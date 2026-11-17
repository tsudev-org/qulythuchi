import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

import 'api_client.dart';

/// Web: trình duyệt tự kiểm TLS (không ghim được trong trang - ADR-0003); cookie phiên cùng gốc.
http.Client createSyncHttpClient() => BrowserClient()..withCredentials = true;
ApiException? mapSyncTransportError(Object error) => null;
const bool syncUsesCookies = true;
