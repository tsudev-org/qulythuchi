// Bảng tiền tệ đang lưu hành theo ISO 4217 (bản sửa đổi tới 2026). Mỗi dòng:
// mã | mã số | số chữ số thập phân | ký hiệu | tên tiếng Anh | tên tiếng Việt (bỏ trống = dùng tên tiếng Anh).
// Mã số dùng để đọc QR thanh toán EMVCo (thẻ 53). Thêm dòng ⇒ giữ thứ tự bảng chữ cái.
const iso4217Table = '''
AED|784|2|د.إ|UAE Dirham|Dirham UAE
AFN|971|2|؋|Afghani|
ALL|008|2|L|Lek|
AMD|051|2|֏|Armenian Dram|
ANG|532|2|ƒ|Netherlands Antillean Guilder|
AOA|973|2|Kz|Kwanza|
ARS|032|2|\$|Argentine Peso|Peso Argentina
AUD|036|2|A\$|Australian Dollar|Đô la Úc
AWG|533|2|ƒ|Aruban Florin|
AZN|944|2|₼|Azerbaijan Manat|
BAM|977|2|KM|Convertible Mark|
BBD|052|2|Bds\$|Barbados Dollar|
BDT|050|2|৳|Taka|Taka Bangladesh
BGN|975|2|лв|Bulgarian Lev|
BHD|048|3|BD|Bahraini Dinar|
BIF|108|0|FBu|Burundi Franc|
BMD|060|2|\$|Bermudian Dollar|
BND|096|2|B\$|Brunei Dollar|Đô la Brunei
BOB|068|2|Bs|Boliviano|
BRL|986|2|R\$|Brazilian Real|Real Brazil
BSD|044|2|B\$|Bahamian Dollar|
BTN|064|2|Nu|Ngultrum|
BWP|072|2|P|Pula|
BYN|933|2|Br|Belarusian Ruble|
BZD|084|2|BZ\$|Belize Dollar|
CAD|124|2|C\$|Canadian Dollar|Đô la Canada
CDF|976|2|FC|Congolese Franc|
CHF|756|2|CHF|Swiss Franc|Franc Thụy Sĩ
CLP|152|0|\$|Chilean Peso|
CNY|156|2|CN¥|Yuan Renminbi|Nhân dân tệ
COP|170|2|\$|Colombian Peso|
CRC|188|2|₡|Costa Rican Colon|
CUP|192|2|\$|Cuban Peso|Peso Cuba
CVE|132|2|Esc|Cabo Verde Escudo|
CZK|203|2|Kč|Czech Koruna|Koruna Séc
DJF|262|0|Fdj|Djibouti Franc|
DKK|208|2|kr|Danish Krone|Krone Đan Mạch
DOP|214|2|RD\$|Dominican Peso|
DZD|012|2|DA|Algerian Dinar|
EGP|818|2|E£|Egyptian Pound|Bảng Ai Cập
ERN|232|2|Nfk|Nakfa|
ETB|230|2|Br|Ethiopian Birr|
EUR|978|2|€|Euro|Euro
FJD|242|2|FJ\$|Fiji Dollar|
FKP|238|2|£|Falkland Islands Pound|
GBP|826|2|£|Pound Sterling|Bảng Anh
GEL|981|2|₾|Lari|
GHS|936|2|GH₵|Ghana Cedi|
GIP|292|2|£|Gibraltar Pound|
GMD|270|2|D|Dalasi|
GNF|324|0|FG|Guinean Franc|
GTQ|320|2|Q|Quetzal|
GYD|328|2|G\$|Guyana Dollar|
HKD|344|2|HK\$|Hong Kong Dollar|Đô la Hồng Kông
HNL|340|2|L|Lempira|
HTG|332|2|G|Gourde|
HUF|348|2|Ft|Forint|Forint Hungary
IDR|360|2|Rp|Rupiah|Rupiah Indonesia
ILS|376|2|₪|New Israeli Sheqel|Shekel Israel
INR|356|2|₹|Indian Rupee|Rupee Ấn Độ
IQD|368|3|ع.د|Iraqi Dinar|
IRR|364|2|﷼|Iranian Rial|
ISK|352|0|kr|Iceland Krona|
JMD|388|2|J\$|Jamaican Dollar|
JOD|400|3|JD|Jordanian Dinar|
JPY|392|0|¥|Yen|Yên Nhật
KES|404|2|KSh|Kenyan Shilling|
KGS|417|2|сом|Som|
KHR|116|2|៛|Riel|Riel Campuchia
KMF|174|0|CF|Comorian Franc|
KPW|408|2|₩|North Korean Won|Won Triều Tiên
KRW|410|0|₩|Won|Won Hàn Quốc
KWD|414|3|KD|Kuwaiti Dinar|Dinar Kuwait
KYD|136|2|CI\$|Cayman Islands Dollar|
KZT|398|2|₸|Tenge|Tenge Kazakhstan
LAK|418|2|₭|Lao Kip|Kíp Lào
LBP|422|2|LL|Lebanese Pound|
LKR|144|2|Rs|Sri Lanka Rupee|
LRD|430|2|L\$|Liberian Dollar|
LSL|426|2|L|Loti|
LYD|434|3|LD|Libyan Dinar|
MAD|504|2|DH|Moroccan Dirham|
MDL|498|2|L|Moldovan Leu|
MGA|969|2|Ar|Malagasy Ariary|
MKD|807|2|ден|Denar|
MMK|104|2|K|Kyat|Kyat Myanmar
MNT|496|2|₮|Tugrik|Tugrik Mông Cổ
MOP|446|2|MOP\$|Pataca|Pataca Ma Cao
MRU|929|2|UM|Ouguiya|
MUR|480|2|₨|Mauritius Rupee|
MVR|462|2|Rf|Rufiyaa|
MWK|454|2|MK|Malawi Kwacha|
MXN|484|2|MX\$|Mexican Peso|Peso Mexico
MYR|458|2|RM|Malaysian Ringgit|Ringgit Malaysia
MZN|943|2|MT|Mozambique Metical|
NAD|516|2|N\$|Namibia Dollar|
NGN|566|2|₦|Naira|Naira Nigeria
NIO|558|2|C\$|Cordoba Oro|
NOK|578|2|kr|Norwegian Krone|Krone Na Uy
NPR|524|2|Rs|Nepalese Rupee|
NZD|554|2|NZ\$|New Zealand Dollar|Đô la New Zealand
OMR|512|3|OMR|Rial Omani|
PAB|590|2|B/.|Balboa|
PEN|604|2|S/|Sol|
PGK|598|2|K|Kina|
PHP|608|2|₱|Philippine Peso|Peso Philippines
PKR|586|2|Rs|Pakistan Rupee|Rupee Pakistan
PLN|985|2|zł|Zloty|Zloty Ba Lan
PYG|600|0|₲|Guarani|
QAR|634|2|QR|Qatari Rial|Rial Qatar
RON|946|2|lei|Romanian Leu|
RSD|941|2|din|Serbian Dinar|
RUB|643|2|₽|Russian Ruble|Rúp Nga
RWF|646|0|FRw|Rwanda Franc|
SAR|682|2|SR|Saudi Riyal|Riyal Ả Rập Xê Út
SBD|090|2|SI\$|Solomon Islands Dollar|
SCR|690|2|SR|Seychelles Rupee|
SDG|938|2|£SD|Sudanese Pound|
SEK|752|2|kr|Swedish Krona|Krona Thụy Điển
SGD|702|2|S\$|Singapore Dollar|Đô la Singapore
SHP|654|2|£|Saint Helena Pound|
SLE|925|2|Le|Leone|
SOS|706|2|Sh|Somali Shilling|
SRD|968|2|\$|Surinam Dollar|
SSP|728|2|£|South Sudanese Pound|
STN|930|2|Db|Dobra|
SVC|222|2|₡|El Salvador Colon|
SYP|760|2|£S|Syrian Pound|
SZL|748|2|E|Lilangeni|
THB|764|2|฿|Baht|Baht Thái
TJS|972|2|SM|Somoni|
TMT|934|2|m|Turkmenistan New Manat|
TND|788|3|DT|Tunisian Dinar|
TOP|776|2|T\$|Pa'anga|
TRY|949|2|₺|Turkish Lira|Lira Thổ Nhĩ Kỳ
TTD|780|2|TT\$|Trinidad and Tobago Dollar|
TWD|901|2|NT\$|New Taiwan Dollar|Đô la Đài Loan
TZS|834|2|TSh|Tanzanian Shilling|
UAH|980|2|₴|Hryvnia|Hryvnia Ukraina
UGX|800|0|USh|Uganda Shilling|
USD|840|2|\$|US Dollar|Đô la Mỹ
UYU|858|2|\$U|Peso Uruguayo|
UYW|927|4|UYW|Unidad Previsional|
UZS|860|2|soʻm|Uzbekistan Sum|
VED|926|2|Bs.D|Bolívar Soberano (digital)|
VES|928|2|Bs.S|Bolívar Soberano|
VND|704|0|₫|Dong|Đồng Việt Nam
VUV|548|0|VT|Vatu|
WST|882|2|WS\$|Tala|
XAF|950|0|FCFA|CFA Franc BEAC|
XCD|951|2|EC\$|East Caribbean Dollar|
XCG|532|2|Cg|Caribbean Guilder|
XOF|952|0|CFA|CFA Franc BCEAO|
XPF|953|0|CFP|CFP Franc|
YER|886|2|﷼|Yemeni Rial|
ZAR|710|2|R|Rand|Rand Nam Phi
ZMW|967|2|ZK|Zambian Kwacha|
ZWG|924|2|ZiG|Zimbabwe Gold|
''';
