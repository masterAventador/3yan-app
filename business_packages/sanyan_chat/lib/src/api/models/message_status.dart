enum MessageStatus {
  sending, // 等 server ack
  sent, // 已 ack
  failed, // 发送失败
}
