# frozen_string_literal: true

Avs::Engine.routes.draw do
  namespace :v0, defaults: { format: 'json' } do
    resource :avs, only: :show
  end
end
