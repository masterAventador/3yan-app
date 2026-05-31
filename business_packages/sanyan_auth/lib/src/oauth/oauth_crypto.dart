import 'dart:convert';
import 'package:crypto/crypto.dart';

/// 对原始 nonce 做 SHA-256 并返回小写 hex。
/// Apple Sign In 要求传 sha256(nonce)，原始 nonce 发服务端比对 token 的 nonce claim。
String sha256Hex(String input) => sha256.convert(utf8.encode(input)).toString();
