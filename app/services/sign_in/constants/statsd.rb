# frozen_string_literal: true

module SignIn
  module Constants
    module Statsd
      STATSD_SIS_AUTHORIZE_SUCCESS = 'api_sis_auth_success'
      STATSD_SIS_AUTHORIZE_FAILURE = 'api_sis_auth_failure'
      STATSD_SIS_CALLBACK_SUCCESS = 'api_sis_callback_success'
      STATSD_SIS_CALLBACK_FAILURE = 'api_sis_callback_failure'
      STATSD_SIS_TOKEN_SUCCESS = 'api_sis_token_success'
      STATSD_SIS_TOKEN_FAILURE = 'api_sis_token_failure'
      STATSD_SIS_REFRESH_SUCCESS = 'api_sis_refresh_success'
      STATSD_SIS_REFRESH_FAILURE = 'api_sis_refresh_failure'
      STATSD_SIS_REVOKE_SUCCESS = 'api_sis_revoke_success'
      STATSD_SIS_REVOKE_FAILURE = 'api_sis_revoke_failure'
      STATSD_SIS_INTROSPECT_SUCCESS = 'api_sis_introspect_success'
      STATSD_SIS_INTROSPECT_FAILURE = 'api_sis_introspect_failure'
      STATSD_SIS_LOGOUT_SUCCESS = 'api_sis_logout_success'
      STATSD_SIS_LOGOUT_FAILURE = 'api_sis_logout_failure'
      STATSD_SIS_REVOKE_ALL_SESSIONS_SUCCESS = 'api_sis_revoke_all_sessions_success'
      STATSD_SIS_REVOKE_ALL_SESSIONS_FAILURE = 'api_sis_revoke_all_sessions_failure'
    end
  end
end
