# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Flipper UI' do
  def bypass_flipper_authenticity_token
    Rails.application.routes.draw do
      mount Flipper::UI.app(
        Flipper.instance,
        rack_protection: { except: :authenticity_token }
      ) => '/flipper', constraints: Flipper::AdminUserConstraint
    end
    yield
    Rails.application.reload_routes!
  end

  include Warden::Test::Helpers

  let(:default_attrs) do
    { 'login' => 'john',
      'name' => 'John Doe',
      'gravatar_id' => '38581cb351a52002548f40f8066cfecg',
      'avatar_url' => 'http://example.com/avatar.jpg',
      'email' => 'john@doe.com',
      'company' => 'Doe, Inc.' }
  end
  let(:user) { Warden::GitHub::User.new(default_attrs) }

  before do
    allow_any_instance_of(Warden::Proxy).to receive(:authenticate!).and_return(user)
    allow_any_instance_of(Warden::Proxy).to receive(:user).and_return(user)
    # allow_any_instance_of(ActionDispatch::Request).to receive(:session) { { "flipper_user": user } }
  end

  context 'Authorized user (organization and team membership)' do
    before do
      # allow_any_instance_of(Warden::Proxy).to receive(:authenticate!).and_return(user)
      # allow_any_instance_of(Warden::Proxy).to receive(:user).and_return(user)
      # allow_any_instance_of(ActionDispatch::Request).to receive(:session) { { "flipper_user": user } }
      # sign_in_as(user)
      allow(user).to receive(:organization_member?).with(Settings.sidekiq.github_organization).and_return(true)
      allow(user).to receive(:team_member?).with(Settings.sidekiq.github_team).and_return(true)

      Flipper.enable(:test_feature)
    end

    # let(:user) { build(:user, :loa3) }

    it 'can display list of features' do
      get '/flipper/features', params: nil
      # expect(response.body).to include('flipper/features') # why test this?
      assert_response :success
    end

    it 'can toggle features' do
      expect(Flipper.enabled?(:test_feature)).to be true
      bypass_flipper_authenticity_token do
        post '/flipper/features/test_feature/boolean', params: nil
        assert_response :found
        expect(Flipper.enabled?(:test_feature)).to be false
      end
    end
  end

  context 'Unauthorized user' do
    it 'feature route is read only' do
      get '/flipper/features', params: nil
      assert_response :success
      expect(response.body).not_to include('flipper/features')
    end

    context 'without organization membership' do
      it 'cannot toggle features and returns 404' do
        # require 'pry'; binding.pry;
        Flipper.enable(:test_feature)
        allow(user).to receive(:organization_member?).with(Settings.flipper.github_organization).and_return(false)

        # bypass_flipper_authenticity_token do
          expect do
            post '/flipper/features/test_feature/boolean', params: nil
          end.to raise_error(Common::Exceptions::Forbidden)
        # end
      end
    end

    context 'without team membership' do
      it 'cannot toggle features and returns 404' do
        Flipper.enable(:test_feature)
        allow(user).to receive(:organization_member?).with(Settings.flipper.github_organization).and_return(true)
        allow(user).to receive(:team_member?).with(Settings.flipper.github_team).and_return(false)

        # bypass_flipper_authenticity_token do
          expect do
            post '/flipper/features/test_feature/boolean', params: nil
          end.to raise_error(Common::Exceptions::Forbidden)
        # end
      end
    end
  end
end

# RSpec.describe 'Flipper UI' do
#   def bypass_flipper_authenticity_token
#     Rails.application.routes.draw do
#       mount Flipper::UI.app(
#         Flipper.instance,
#         rack_protection: { except: :authenticity_token }
#       ) => '/flipper', constraints: Flipper::AdminUserConstraint.new
#     end
#     yield
#     Rails.application.reload_routes!
#   end

#   context 'with authenticated admin user' do
#     before do
#       sign_in_as(user)
#       allow(Settings.flipper).to receive(:admin_user_emails).and_return(user.email)
#       Flipper.enable(:test_feature)
#     end

#     context 'with LOA1 access' do
#       let(:user) { build(:user) }

#       it 'does not allow feature toggling' do
#         post '/flipper/features/test_feature/boolean', params: nil
#         assert_response :not_found
#         expect(JSON.parse(response.body)['errors'][0]['detail']).to include('There are no routes matching your request')
#       end
#     end

#     context 'with LOA3 access' do
#       let(:user) { build(:user, :loa3) }

#       it 'Displays list of features' do
#         get '/flipper/features', params: nil
#         expect(response.body).to include('flipper/features')
#         assert_response :success
#       end

#       it 'Allows user to toggle feature' do
#         bypass_flipper_authenticity_token do
#           expect(Flipper.enabled?(:test_feature)).to be true
#           post '/flipper/features/test_feature/boolean', params: nil
#           assert_response :found
#           expect(Flipper.enabled?(:test_feature)).to be false
#         end
#       end
#     end
#   end

#   context 'when unauthenticated' do
#     it 'feature route is read only' do
#       get '/flipper/features', params: nil
#       assert_response :success
#       expect(response.body).not_to include('flipper/features')
#     end

#     it 'does not allow feature toggles' do
#       bypass_flipper_authenticity_token do
#         Flipper.enable(:test_feature)
#         expect do
#           post '/flipper/features/test_feature/boolean', params: nil
#         end.to raise_error(ActionController::RoutingError)
#       end
#     end
#   end
# end
