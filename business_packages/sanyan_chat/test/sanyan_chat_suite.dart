import 'chat_api_test.dart' as chat_api_test;
import 'message_bubble_max_width_test.dart' as message_bubble_test;
import 'relationship_req_test.dart' as relationship_req_test;
import 'chat/widgets/intimacy_progress_bar_test.dart' as progress_bar_test;
import 'chat/widgets/stage_transition_dialog_test.dart' as transition_dialog_test;
import 'chat/chat_controller_test.dart' as chat_controller_test;

void main() {
  chat_api_test.main();
  message_bubble_test.main();
  relationship_req_test.main();
  progress_bar_test.main();
  transition_dialog_test.main();
  chat_controller_test.main();
}
