#ifndef RUNNER_OCR_CHANNEL_H_
#define RUNNER_OCR_CHANNEL_H_

#include <flutter/binary_messenger.h>
#include <windows.h>

// OCR hoa don tren may bang Windows.Media.Ocr (ADR-0021). Kenh `com.tsudev.qulythuchi/ocr`, phuong thuc `recognize`
// (Uint8List anh) -> String (moi dong mot dong). Nhan dang chay tren luong nen; ket qua tro ve luong nen tang qua
// PostMessage(kOcrResultMessage) toi cua so chinh vi kenh Flutter chi duoc tra loi tren luong nen tang.
constexpr UINT kOcrResultMessage = WM_APP + 0x51;

void RegisterOcrChannel(flutter::BinaryMessenger* messenger, HWND window);

// Goi tu FlutterWindow::MessageHandler khi nhan kOcrResultMessage.
void DeliverOcrResult(LPARAM lparam);

#endif  // RUNNER_OCR_CHANNEL_H_
