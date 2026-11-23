# google_mlkit_text_recognition tham chiếu bộ nhận dạng chữ Trung/Nhật/Hàn/Devanagari; app chỉ đóng gói chữ Latin
# (hoá đơn tiếng Việt) nên các lớp đó cố ý vắng mặt - R8 bỏ qua thay vì dừng dựng.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
