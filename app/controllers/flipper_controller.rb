# frozen_string_literal: true

class FlipperController < ApplicationController
  skip_before_action :authenticate
  def logout
    puts '****logout****'
    cookies.delete :api_session
    # session.delete :flipper_user
    puts '*****session deleted******'
    # flash[:notice] = "You have successfully logged out."

    redirect_to '/flipper/features'
  end
end
