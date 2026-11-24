#include "ocr_channel.h"

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Globalization.h>
#include <winrt/Windows.Graphics.Imaging.h>
#include <winrt/Windows.Media.Ocr.h>
#include <winrt/Windows.Storage.Streams.h>

#include <algorithm>
#include <memory>
#include <string>
#include <thread>
#include <utility>
#include <variant>
#include <vector>

namespace {

using flutter::EncodableValue;
using OcrResultSink = flutter::MethodResult<EncodableValue>;

// Tran anh vao, cung tran ImageSanitizer (ADR-0017) va phia Dart.
constexpr size_t kMaxImageBytes = 25u * 1024u * 1024u;

struct OcrJob {
  std::unique_ptr<OcrResultSink> result;
  std::string text;
  std::string error_code;  // rong = thanh cong
  std::string error_message;
};

std::unique_ptr<flutter::MethodChannel<EncodableValue>> g_channel;

// Uu tien tieng Viet, roi ngon ngu ho so nguoi dung, roi ngon ngu OCR dau tien da cai.
winrt::Windows::Media::Ocr::OcrEngine CreateEngine() {
  using winrt::Windows::Media::Ocr::OcrEngine;
  auto langs = OcrEngine::AvailableRecognizerLanguages();
  for (auto const& lang : langs) {
    std::wstring tag{lang.LanguageTag()};
    if (tag == L"vi" || tag.rfind(L"vi-", 0) == 0) {
      if (auto e = OcrEngine::TryCreateFromLanguage(lang)) return e;
    }
  }
  if (auto e = OcrEngine::TryCreateFromUserProfileLanguages()) return e;
  if (langs.Size() > 0) return OcrEngine::TryCreateFromLanguage(langs.GetAt(0));
  return nullptr;
}

void Recognize(OcrJob* job, std::vector<uint8_t> const& bytes) {
  using namespace winrt::Windows::Graphics::Imaging;
  using winrt::Windows::Media::Ocr::OcrEngine;
  using winrt::Windows::Storage::Streams::DataWriter;
  using winrt::Windows::Storage::Streams::InMemoryRandomAccessStream;
  try {
    auto engine = CreateEngine();
    if (!engine) {
      job->error_code = "no_language";
      job->error_message = "No OCR language installed";
      return;
    }
    InMemoryRandomAccessStream stream;
    DataWriter writer(stream);
    writer.WriteBytes(bytes);
    writer.StoreAsync().get();
    writer.DetachStream();
    stream.Seek(0);
    auto decoder = BitmapDecoder::CreateAsync(stream).get();
    BitmapTransform transform;
    const uint32_t w = decoder.PixelWidth();
    const uint32_t h = decoder.PixelHeight();
    const uint32_t max_dim = OcrEngine::MaxImageDimension();
    if (w > max_dim || h > max_dim) {
      const double s = static_cast<double>(max_dim) / static_cast<double>((std::max)(w, h));
      transform.ScaledWidth((std::max)(1u, static_cast<uint32_t>(w * s)));
      transform.ScaledHeight((std::max)(1u, static_cast<uint32_t>(h * s)));
      transform.InterpolationMode(BitmapInterpolationMode::Fant);
    }
    auto bitmap = decoder
                      .GetSoftwareBitmapAsync(BitmapPixelFormat::Bgra8, BitmapAlphaMode::Premultiplied, transform,
                                              ExifOrientationMode::RespectExifOrientation,
                                              ColorManagementMode::DoNotColorManage)
                      .get();
    auto result = engine.RecognizeAsync(bitmap).get();
    std::wstring text;
    for (auto const& line : result.Lines()) {
      text += line.Text();
      text += L'\n';
    }
    job->text = winrt::to_string(text);
  } catch (winrt::hresult_error const& e) {
    // Chi ma loi HRESULT - khong dua noi dung anh/van ban vao thong bao loi (D3).
    job->error_code = "failed";
    job->error_message = "HRESULT " + std::to_string(static_cast<int32_t>(e.code()));
  } catch (...) {
    job->error_code = "failed";
    job->error_message = "unknown";
  }
}

}  // namespace

void RegisterOcrChannel(flutter::BinaryMessenger* messenger, HWND window) {
  g_channel = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      messenger, "com.tsudev.qulythuchi/ocr", &flutter::StandardMethodCodec::GetInstance());
  g_channel->SetMethodCallHandler([window](const flutter::MethodCall<EncodableValue>& call,
                                           std::unique_ptr<OcrResultSink> result) {
    if (call.method_name() != "recognize") {
      result->NotImplemented();
      return;
    }
    const auto* args = call.arguments();
    const auto* bytes = args ? std::get_if<std::vector<uint8_t>>(args) : nullptr;
    if (!bytes || bytes->empty() || bytes->size() > kMaxImageBytes) {
      result->Error("bad_args", "Expected image bytes (<= 25 MiB)");
      return;
    }
    auto* job = new OcrJob{std::move(result)};
    std::thread([job, window, data = *bytes]() {
      winrt::init_apartment(winrt::apartment_type::multi_threaded);
      Recognize(job, data);
      winrt::uninit_apartment();
      if (!PostMessage(window, kOcrResultMessage, 0, reinterpret_cast<LPARAM>(job))) {
        // Cua so da dong (app dang thoat): bo ket qua.
        job->result.release();
        delete job;
      }
    }).detach();
  });
}

void DeliverOcrResult(LPARAM lparam) {
  std::unique_ptr<OcrJob> job(reinterpret_cast<OcrJob*>(lparam));
  if (job->error_code.empty()) {
    job->result->Success(EncodableValue(job->text));
  } else {
    job->result->Error(job->error_code, job->error_message);
  }
}
