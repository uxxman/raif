# frozen_string_literal: true

Raif::Engine.routes.draw do
  resources :conversations, only: [] do
    resources :conversation_entries, only: [:new, :create], as: :entries, path: "entries"
  end
end
