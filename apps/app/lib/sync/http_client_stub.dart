import 'package:http/http.dart' as http;

import 'api_client.dart';

http.Client createSyncHttpClient() => throw UnsupportedError('Nền tảng không hỗ trợ');
ApiException? mapSyncTransportError(Object error) => null;
const bool syncUsesCookies = false;
