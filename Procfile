web: bundle exec puma -t 4:4 -p ${PORT:-3000} -e ${RACK_ENV:-development}
worker: bundle exec sidekiq -c ${SIDEKIQ_CONCURRENCY:-5} -r ./bootup.rb