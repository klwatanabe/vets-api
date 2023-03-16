module MockedAuthentication
  module MockedCredential
    class Service
      def token(code)
        code
      end

      def user_info(token)
        mocked_authorization_credential_information = MockedAuthRedis.find(token)
        OpenStruct.new(mocked_authorization_credential_information)
      end

      def normalized_attributes(user_info, credential_level)
        {
          logingov_uuid: user_info.sub,
          current_ial: credential_level.current_ial,
          max_ial: credential_level.max_ial,
          ssn: user_info.social_security_number&.tr('-', ''),
          birth_date: user_info.birthdate,
          first_name: user_info.given_name,
          last_name: user_info.family_name,
          address: normalize_address(user_info.address),
          csp_email: user_info.email,
          multifactor: true,
          service_name: 'logingov',
          authn_context: get_authn_context(credential_level.current_ial),
          auto_uplevel: credential_level.auto_uplevel
        }
      end

      private

      def normalize_address(address)
        return unless address

        street_array = address[:street_address].split("\n")
        {
          street: street_array[0],
          street2: street_array[1],
          postal_code: address[:postal_code],
          state: address[:region],
          city: address[:locality],
          country: united_states_country_code
        }
      end

      def united_states_country_code
        'USA'
      end

      def get_authn_context(current_ial)
        current_ial == IAL::TWO ? IAL::LOGIN_GOV_IAL2 : IAL::LOGIN_GOV_IAL1
      end
    end
  end
end
