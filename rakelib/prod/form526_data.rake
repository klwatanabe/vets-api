# frozen_string_literal: true

namespace :form526_data do
  def log_or_stdout(d)

  end

  def get_data_by_ids(ids, batch_size)
    # subs = File.read('/tmp/ids.txt').lines.map(&:chomp)
    z=0
    data = []
    Form526Submission.where(id: ids).find_in_batches(batch_size: batch_size) do |group|
      z+=1
      puts "#{Time.now} - Batch #{z}"
      group.each do |sub|
        form = sub.form['form526']['form526']
        auth = sub.auth_headers
        pid = auth['va_eauth_pid']
        form['disabilities'].each do |d|
          x = [pid, sub.created_at, d['name']].to_csv
          data << x 
          print "."
        end        
      end
    end
    File.write('/tmp/disability_data.csv', data.join)
  end

  desc 'Gather 526 Data, based on a file of IDs'
  # bin/rake form526_data:get_by_id_file[/tmp/ids.txt]
  # bin/rake form526_data:get_by_id_file[/tmp/ids.txt,1000]
  task :get_by_id_file, [:input_file, :batch_size] => :environment do |_, args|
    args.with_defaults(batch_size: 100) 
    pp args

    Rails.logger.info([task, args])
  end

  task :get_by_csv_string_of_ids, [:ids, :batch_size] => :environment do |_, args|
    args.with_defaults(batch_size: 100) 
    pp args

    Rails.logger.info([task, args])
  end
end
