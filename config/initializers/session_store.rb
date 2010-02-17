# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_blacklight-app_session',
  :secret      => 'd67cde6b7c0c237b278e6f8191d009f6c1f5a9a0b147c065fb15cf461456d836c8a083f05c9847cdfed1ac2b3b503380229ad72f0087cf1f522199da6ffba300'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
