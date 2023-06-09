# frozen_string_literal: true

require 'rails_helper'
require AppealsApi::Engine.root.join('spec', 'support', 'shared_examples_for_monitored_worker.rb')

describe AppealsApi::IcnSsnLookupStats, type: :job do
  it_behaves_like 'a monitored worker'

  describe '#perform' do
    context 'with an hlr' do
      let(:hlr) { create(:extra_higher_level_review_v2) }

      it 'hlr logs statsd with found mpi icn lookup and profile icn matches api consumer provided icn' do
        profile = double('profile', { ssn: '123456789' })
        response = double('response', { profile: })
        allow_any_instance_of(MPI::Service).to receive(:find_profile_by_identifier).and_return(response)
        expect { described_class.new.perform(hlr.id, hlr.class.to_s) }
          .to trigger_statsd_increment('api.appeals.icn.lookup.ssn',
                                       tags: ['profile_found:true', 'ssn_matched:true'], times: 1)
      end

      it 'logs statsd with missed mpi icn lookup' do
        response = double('response', { profile: nil })
        allow_any_instance_of(MPI::Service).to receive(:find_profile_by_identifier).and_return(response)
        expect { described_class.new.perform(hlr.id, hlr.class.to_s) }
          .to trigger_statsd_increment('api.appeals.icn.lookup.ssn',
                                       tags: ['profile_found:false', 'ssn_matched:na'], times: 1)
      end

      it 'logs statsd with profile found but missing ssn' do
        profile = double('profile', { ssn: nil })
        response = double('response', { profile: })
        allow_any_instance_of(MPI::Service).to receive(:find_profile_by_identifier).and_return(response)
        expect { described_class.new.perform(hlr.id, hlr.class.to_s) }
          .to trigger_statsd_increment('api.appeals.icn.lookup.ssn',
                                       tags: ['profile_found:true', 'ssn_matched:na'], times: 1)
      end

      it 'logs statsd with profile found but profile ssn does not match provided ssn' do
        profile = double('profile', { ssn: '54321' })
        response = double('response', { profile: })
        allow_any_instance_of(MPI::Service).to receive(:find_profile_by_identifier).and_return(response)
        expect { described_class.new.perform(hlr.id, hlr.class.to_s) }
          .to trigger_statsd_increment('api.appeals.icn.lookup.ssn',
                                       tags: ['profile_found:true', 'ssn_matched:false'], times: 1)
      end
    end

    context 'with a sc' do
      let(:sc) { create(:extra_supplemental_claim) }

      it 'sc logs statsd with found mpi icn lookup and profile icn matches api consumer provided icn' do
        profile = double('profile', { ssn: '123456789' })
        response = double('response', { profile: })
        allow_any_instance_of(MPI::Service).to receive(:find_profile_by_identifier).and_return(response)
        expect { described_class.new.perform(sc.id, sc.class.to_s) }
          .to trigger_statsd_increment('api.appeals.icn.lookup.ssn',
                                       tags: ['profile_found:true', 'ssn_matched:true'], times: 1)
      end
    end

  end
end
