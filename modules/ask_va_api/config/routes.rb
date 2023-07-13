# frozen_string_literal: true

AskVAApi::Engine.routes.draw do
  namespace :v0 do
    resources :data, only: %i[index]
    resources :data_off, only: %i[index]
  end
end
