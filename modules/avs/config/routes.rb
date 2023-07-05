# frozen_string_literal: true

Avs::Engine.routes.draw do
  namespace :v0, defaults: { format: 'json' } do
    get '/avs', to: 'avs#index'
    get '/avs/:id', to: 'avs#show'
  end
end
