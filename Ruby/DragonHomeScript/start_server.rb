
load 'start.rb'

require 'sinatra'
require 'sinatra/json'

set :bind, '0.0.0.0'
set :port, 4568

helpers do
	def is_authorized?
		user = params['user']
		key = params['apikey']

		if($core.users[user].nil?)
			return false
		elsif($core.users[user].apikey.nil? || $core.users[user].apikey != key)
			return false
		end

		true
	end
end

get '/api/dragonHome/switchUser' do
	return 401 unless is_authorized?

	if(params.include? 'name')
		n = params['name'].gsub(/(^\s+)|(\s+$)/, '');
		
		n = nil if(n == 'undefined' || n == 'undef' || n == 'nil' || n == 'null')
		
		$core.users[params['user']].name = n;
	end

	if(params.include? 'awake')
		$core.users[params['user']].awake = true	if params['awake'] == 'true'
		$core.users[params['user']].awake = false if params['awake'] == 'false'
	end

	204
end

get '/api/dragonHome/userInfo' do
	user = $core.users[params['user']]

	return json({
		ok: false
	}) if user.nil?

	return json({
		username: params['user'],
		switchedName: user.name,
		awake: user.awake
	})
end

get '/api/dragonHome/switchedUserBadge' do
	user = $core.users[params['user']]

	return json({
		schemaVersion: 1,
		label: "Who's in?",
		message: 'Invalid user!',
		color: 'red',
		isError: true
	}) if user.nil?

	return json({
		schemaVersion: 1,
		label: "Who's in?",
		message: user.name,
		color: 'green',
	})
end