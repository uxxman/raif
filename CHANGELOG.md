## 1.0.1

- If a `creator` association implements `raif_display_name`, it will be used in the admin interface.
- Agent types can now implement `populate_default_model_tools` to add default model tools to the agent. `Raif::Agents::ReActAgent` will provide these via system prompt.
- `Raif::ModelTools::AgentFinalAnswer` removed from the default list of model tools for `Raif::Agents::ReActAgent` since answers are provided via `<answer>` tags.
- Estimated cost is now displayed in the admin interface for model completions.