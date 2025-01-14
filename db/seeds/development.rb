# frozen_string_literal: true

require 'sign_in/constants/auth'

# Create Config for va.gov Sign in Service client
vaweb = SignIn::ClientConfig.find_or_initialize_by(client_id: 'vaweb')
vaweb.update!(authentication: SignIn::Constants::Auth::COOKIE,
              anti_csrf: true,
              redirect_uri: 'http://localhost:3001/auth/login/callback',
              access_token_duration: SignIn::Constants::AccessToken::VALIDITY_LENGTH_SHORT_MINUTES,
              access_token_audience: 'va.gov',
              pkce: true,
              logout_redirect_uri: 'http://localhost:3001',
              refresh_token_duration: SignIn::Constants::RefreshToken::VALIDITY_LENGTH_SHORT_MINUTES)

# Create Config for VA flagship mobile Sign in Service client
vamobile = SignIn::ClientConfig.find_or_initialize_by(client_id: 'vamobile')
vamobile.update!(authentication: SignIn::Constants::Auth::API,
                 anti_csrf: false,
                 redirect_uri: 'vamobile://login-success',
                 pkce: true,
                 access_token_duration: SignIn::Constants::AccessToken::VALIDITY_LENGTH_LONG_MINUTES,
                 access_token_audience: 'vamobile',
                 refresh_token_duration: SignIn::Constants::RefreshToken::VALIDITY_LENGTH_LONG_DAYS)

# Create Config for localhost mocked authentication client
vamobile_mock = SignIn::ClientConfig.find_or_initialize_by(client_id: 'vamobile_test')
vamobile_mock.update!(authentication: SignIn::Constants::Auth::API,
                      anti_csrf: false,
                      redirect_uri: 'http://localhost:4001/auth/sis/login-success',
                      pkce: true,
                      access_token_duration: SignIn::Constants::AccessToken::VALIDITY_LENGTH_LONG_MINUTES,
                      access_token_audience: 'vamobile',
                      refresh_token_duration: SignIn::Constants::RefreshToken::VALIDITY_LENGTH_LONG_DAYS)

# Create Config for localhost mocked authentication client
vamock = SignIn::ClientConfig.find_or_initialize_by(client_id: 'vamock')
vamock.update!(authentication: SignIn::Constants::Auth::MOCK,
               anti_csrf: true,
               pkce: true,
               redirect_uri: 'http://localhost:3001/auth/login/callback',
               access_token_duration: SignIn::Constants::AccessToken::VALIDITY_LENGTH_SHORT_MINUTES,
               access_token_audience: 'va.gov',
               logout_redirect_uri: 'http://localhost:3001',
               refresh_token_duration: SignIn::Constants::RefreshToken::VALIDITY_LENGTH_SHORT_MINUTES)

# Create Config for example external client using cookie auth
sample_client_web = SignIn::ClientConfig.find_or_initialize_by(client_id: 'sample_client_web')
sample_client_web.update!(authentication: SignIn::Constants::Auth::COOKIE,
                          anti_csrf: true,
                          pkce: true,
                          redirect_uri: 'http://localhost:4567/auth/result',
                          access_token_duration: SignIn::Constants::AccessToken::VALIDITY_LENGTH_SHORT_MINUTES,
                          access_token_audience: 'sample_client',
                          logout_redirect_uri: 'http://localhost:4567',
                          refresh_token_duration: SignIn::Constants::RefreshToken::VALIDITY_LENGTH_SHORT_MINUTES)

# Create Config for example external client using api auth
sample_client_api = SignIn::ClientConfig.find_or_initialize_by(client_id: 'sample_client_api')
sample_client_api.update!(authentication: SignIn::Constants::Auth::API,
                          anti_csrf: false,
                          pkce: true,
                          redirect_uri: 'http://localhost:4567/auth/result',
                          access_token_duration: SignIn::Constants::AccessToken::VALIDITY_LENGTH_SHORT_MINUTES,
                          access_token_audience: 'sample_client',
                          logout_redirect_uri: 'http://localhost:4567',
                          refresh_token_duration: SignIn::Constants::RefreshToken::VALIDITY_LENGTH_SHORT_MINUTES)

# Create Config for VA Identity Dashboard using cookie auth
vaid_dash = SignIn::ClientConfig.find_or_initialize_by(client_id: 'identity_dashboard')
vaid_dash.update!(authentication: SignIn::Constants::Auth::COOKIE,
                  anti_csrf: true,
                  pkce: true,
                  redirect_uri: 'http://localhost:3001/auth/login/callback',
                  access_token_duration: SignIn::Constants::AccessToken::VALIDITY_LENGTH_SHORT_MINUTES,
                  access_token_audience: 'sample_client',
                  access_token_attributes: %w[first_name last_name email],
                  logout_redirect_uri: 'http://localhost:3001',
                  refresh_token_duration: SignIn::Constants::RefreshToken::VALIDITY_LENGTH_SHORT_MINUTES)

# Create Service Account Config for VA Identity Dashboard Service Account auth
vaid_certificate = File.read('spec/fixtures/sign_in/identity_dashboard_service_account.crt')
vaid_service_account_id = '01b8ebaac5215f84640ade756b645f28'
vaid_access_token_duration = SignIn::Constants::AccessToken::VALIDITY_LENGTH_SHORT_MINUTES
identity_dashboard_service_account_config =
  SignIn::ServiceAccountConfig.find_or_initialize_by(service_account_id: vaid_service_account_id)
identity_dashboard_service_account_config.update!(service_account_id: vaid_service_account_id,
                                                  description: 'VA Identity Dashboard API',
                                                  scopes: ['http://localhost:3000/sign_in/client_configs'],
                                                  access_token_audience: 'http://localhost:4000',
                                                  access_token_duration: vaid_access_token_duration,
                                                  certificates: [vaid_certificate])
