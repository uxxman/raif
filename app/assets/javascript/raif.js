// Register all Raif controllers
import { application } from "controllers/application"

import ConversationsController from "raif/controllers/conversations_controller"
application.register("raif--conversations", ConversationsController)

export { ConversationsController }

import "raif/stream_actions/raif_scroll_to_bottom"

