#!/usr/bin/env ruby

require 'rubygems'
require 'test/spec'
require 'nymble'

describe 'Nymble' do
  before do
    @hmac_key_np      = Nymble.digest('hmac_key_np')
    @server_id        = Nymble.digest('server_id')
    @user_id          = Nymble.digest('user_id')
    @cur_time_period  = 1
    @cur_link_window  = 1
    $L                = 288
  end

  it 'should have a hash function' do
    Nymble.should.respond_to(:hash)
    Nymble.digest(nil).should.not.be.nil
    Nymble.digest('test').should.not.be.nil
  end

  it 'should manage PM state' do
    Nymble.should.respond_to(:pm_initialize)
    Nymble.pm_initialize(@hmac_key_np).should.not.be.nil
    should.raise(TypeError) { Nymble.pm_initialize(nil) }
    should.raise(ArgumentError) { Nymble.pm_initialize(@hmac_key_np * 2) }
    should.raise(ArgumentError) { Nymble.pm_initialize("") }
  end
  
  it 'should manage NM state' do
    Nymble.should.respond_to(:nm_initialize)
    should.raise(TypeError) { Nymble.nm_initialize(nil) }
    nm_state = Nymble.nm_initialize(@hmac_key_np)
    nm_state.should.not.be.nil
    
    Nymble.should.respond_to(:nm_verify_key)
    should.raise(TypeError) { Nymble.nm_verify_key(nil) }
    Nymble.nm_verify_key(nm_state).should.not.be.nil
  end

  it 'should allow a NM to register servers' do
    nm_state = Nymble.nm_initialize(@hmac_key_np)
    nm_state2 = Nymble.nm_initialize(@hmac_key_np.reverse)
    
    Nymble.should.respond_to(:nm_entry_exists)
    should.raise(TypeError) { Nymble.nm_entry_exists(nil, @server_id) }
    should.raise(TypeError) { Nymble.nm_entry_exists(nm_state, nil) }
    Nymble.nm_entry_exists(nm_state, @server_id).should.be(false)
    
    Nymble.should.respond_to(:nm_entry_add)
    should.raise(TypeError) { Nymble.nm_entry_add(nm_state, nil) }
    should.raise(ArgumentError) { Nymble.nm_entry_add(nm_state, "") }
    should.raise(ArgumentError) { Nymble.nm_entry_exists(nm_state, "") }
    should.raise(TypeError) { Nymble.nm_entry_add(nil, @server_id) }
    should.raise(TypeError) { Nymble.nm_entry_exists(nm_state, nil) }

    hmac_key_ns = Nymble.nm_entry_add(nm_state, @server_id).should.not.be.nil
    Nymble.nm_entry_exists(nm_state, @server_id).should.be(true)
    Nymble.nm_entry_exists(nm_state2, @server_id).should.be(false)
    Nymble.nm_entry_add(nm_state, @server_id.reverse).should.not.equal(hmac_key_ns)
    
    Nymble.should.respond_to(:nm_entry_update)
    should.raise(TypeError) { Nymble.nm_entry_update(nil, @server_id, @cur_time_period) }
    should.raise(TypeError) { Nymble.nm_entry_update(nm_state, nil, @cur_time_period) }
    should.raise(TypeError) { Nymble.nm_entry_update(nm_state, @server_id, nil) }
    should.raise(TypeError) { Nymble.nm_entry_exists(nm_state, nil) }
    Nymble.nm_entry_update(nm_state, @server_id.reverse, @cur_time_period).should.be(true)
    Nymble.nm_entry_update(nm_state, @server_id, @cur_time_period).should.be(true)
    Nymble.nm_entry_update(nm_state2, @server_id, @cur_time_period).should.be(false)
    Nymble.nm_entry_exists(nm_state, @server_id).should.be(true)
    Nymble.nm_entry_exists(nm_state2, @server_id).should.be(false)
  end

  it 'should allow a PM to create psuedonyms' do
    pm_state  = Nymble.pm_initialize(@hmac_key_np)
    nm_state  = Nymble.nm_initialize(@hmac_key_np)
    pm_state2 = Nymble.pm_initialize(@hmac_key_np.reverse)
    
    Nymble.should.respond_to(:pm_pseudonym_create)
    should.raise(TypeError) { Nymble.pm_pseudonym_create(nil, @user_id, @cur_link_window) }
    should.raise(TypeError) { Nymble.pm_pseudonym_create(pm_state, nil, @cur_link_window) }
    should.raise(TypeError) { Nymble.pm_pseudonym_create(pm_state, @user_id, nil) }
    
    pseudonym, mac_np   = Nymble.pm_pseudonym_create(pm_state, @user_id, @cur_link_window)
    pseudonym.should.not.be.nil
    mac_np.should.not.be.nil
    
    pseudonym2, mac_np2 = Nymble.pm_pseudonym_create(pm_state, @user_id, @cur_link_window)
    pseudonym.should.equal(pseudonym2)
    mac_np.should.equal(mac_np2)
    
    pseudonym3, mac_np3 = Nymble.pm_pseudonym_create(pm_state, @user_id.reverse, @cur_link_window)
    pseudonym.should.not.equal(pseudonym3)
    mac_np.should.not.equal(mac_np3)

    pseudonym4, mac_np4 = Nymble.pm_pseudonym_create(pm_state, @user_id, @cur_link_window + 1)
    pseudonym.should.not.equal(pseudonym4)
    mac_np.should.not.equal(mac_np4)
    
    pseudonym5, mac_np5 = Nymble.pm_pseudonym_create(pm_state2, @user_id, @cur_link_window)
    pseudonym.should.not.equal(pseudonym5)
    mac_np.should.not.equal(mac_np5)
  end

  it 'should allow a NM to create blacklists' do
    pm_state          = Nymble.pm_initialize(@hmac_key_np)
    nm_state          = Nymble.nm_initialize(@hmac_key_np)
    nm_state2         = Nymble.nm_initialize(@hmac_key_np.reverse)
    hmac_key_ns       = Nymble.nm_entry_add(nm_state, @server_id)
    pseudonym, mac_np = Nymble.pm_pseudonym_create(pm_state, @user_id, @cur_link_window)
    
    Nymble.should.respond_to(:nm_blacklist_create)
    should.raise(TypeError) { Nymble.nm_blacklist_create(nil, @server_id, @cur_time_period, @cur_link_window) }
    should.raise(TypeError) { Nymble.nm_blacklist_create(nm_state, nil, @cur_time_period, @cur_link_window) }
    should.raise(TypeError) { Nymble.nm_blacklist_create(nm_state, @server_id, nil, @cur_link_window) }
    Nymble.nm_blacklist_create(nm_state, @server_id, $L, @cur_link_window).should.not.be.nil
    Nymble.nm_blacklist_create(nm_state, @server_id, $L + 1, @cur_link_window).should.be.nil
    should.raise(TypeError) { Nymble.nm_blacklist_create(nm_state, @server_id, @cur_time_period, nil) }

    blacklist = Nymble.nm_blacklist_create(nm_state, @server_id, @cur_time_period, @cur_link_window)
    blacklist.should.not.be.nil
    
    Nymble.should.respond_to(:nm_blacklist_verify)
    should.raise(TypeError) { Nymble.nm_blacklist_verify(nil, blacklist, @server_id, @cur_link_window) }
    should.raise(TypeError) { Nymble.nm_blacklist_verify(nm_state, nil, @server_id, @cur_link_window) }
    should.raise(TypeError) { Nymble.nm_blacklist_verify(nm_state, blacklist, nil, @cur_link_window) }
    should.raise(TypeError) { Nymble.nm_blacklist_verify(nm_state, blacklist, @server_id, nil) }
    Nymble.nm_blacklist_verify(nm_state, blacklist, @server_id, @cur_link_window).should.be(true)
    Nymble.nm_blacklist_verify(nm_state2, blacklist, @server_id, @cur_link_window).should.be(false)
    
    Nymble.nm_entry_update(nm_state, @server_id, @cur_time_period)
    Nymble.nm_blacklist_verify(nm_state, blacklist, @server_id, @cur_link_window).should.be(true)
    Nymble.nm_blacklist_verify(nm_state, blacklist, @server_id, @cur_link_window + 1).should.be(false)
    Nymble.nm_blacklist_verify(nm_state2, blacklist, @server_id, @cur_link_window).should.be(false)
  end
  
  it 'should manage SERVER state' do
    pm_state          = Nymble.pm_initialize(@hmac_key_np)
    nm_state          = Nymble.nm_initialize(@hmac_key_np)
    hmac_key_ns       = Nymble.nm_entry_add(nm_state, @server_id)
    pseudonym, mac_np = Nymble.pm_pseudonym_create(pm_state, @user_id, @cur_link_window)
    blacklist         = Nymble.nm_blacklist_create(nm_state, @server_id, @cur_time_period, @cur_link_window)

    Nymble.should.respond_to(:server_initialize)
    should.raise(TypeError) { Nymble.server_initialize(nil, hmac_key_ns, blacklist) }
    should.raise(TypeError) { Nymble.server_initialize(@server_id, nil, blacklist) }
    should.raise(TypeError) { Nymble.server_initialize(@server_id, hmac_key_ns, nil) }
    should.raise(ArgumentError) { Nymble.server_initialize("", hmac_key_ns, blacklist) }
    should.raise(ArgumentError) { Nymble.server_initialize(@server_id, "", blacklist) }

    server_state = Nymble.server_initialize(@server_id, hmac_key_ns, blacklist)
    server_state.should.not.be.nil
    
    Nymble.should.respond_to(:server_blacklist)
    should.raise(TypeError) { Nymble.server_blacklist(nil) }
    
    Nymble.should.respond_to(:server_blacklist_finalized)
    should.raise(TypeError) { Nymble.server_blacklist_finalized(nil, @cur_time_period) }
    Nymble.server_blacklist_finalized(server_state, @cur_time_period).should.be(false)
    Nymble.server_blacklist_finalize(server_state).should.be(true)
    Nymble.server_blacklist_finalized(server_state, @cur_time_period).should.be(true)
  end

  it 'should allow a NM to create credentials' do
    pm_state          = Nymble.pm_initialize(@hmac_key_np)
    nm_state          = Nymble.nm_initialize(@hmac_key_np)
    nm_state2         = Nymble.nm_initialize(@hmac_key_np.reverse)
    hmac_key_ns       = Nymble.nm_entry_add(nm_state, @server_id)
    pseudonym, mac_np = Nymble.pm_pseudonym_create(pm_state, @user_id, @cur_link_window)
    blacklist         = Nymble.nm_blacklist_create(nm_state, @server_id, @cur_time_period, @cur_link_window)
    
    Nymble.should.respond_to(:nm_pseudonym_verify)
    should.raise(TypeError) { Nymble.nm_pseudonym_verify(nil, pseudonym, @cur_link_window, mac_np) }
    should.raise(TypeError) { Nymble.nm_pseudonym_verify(nm_state, nil, @cur_link_window, mac_np) }
    should.raise(TypeError) { Nymble.nm_pseudonym_verify(nm_state, pseudonym, nil, mac_np) }
    should.raise(TypeError) { Nymble.nm_pseudonym_verify(nm_state, pseudonym, @cur_link_window, nil) }
    Nymble.nm_pseudonym_verify(nm_state, pseudonym, @cur_link_window, mac_np.reverse).should.be(false)
    Nymble.nm_pseudonym_verify(nm_state, pseudonym, @cur_link_window + 1, mac_np).should.be(false)
    Nymble.nm_pseudonym_verify(nm_state2, pseudonym, @cur_link_window, mac_np).should.be(false)
    should.raise(ArgumentError) { Nymble.nm_pseudonym_verify(nm_state, "", @cur_link_window, mac_np) }
    should.raise(ArgumentError) { Nymble.nm_pseudonym_verify(nm_state, pseudonym, @cur_link_window, "") }
    Nymble.nm_pseudonym_verify(nm_state, pseudonym, @cur_link_window, mac_np).should.be(true)

    Nymble.should.respond_to(:nm_credential_create)
    should.raise(TypeError) { Nymble.nm_credential_create(nil, pseudonym, @server_id, @cur_link_window) }
    should.raise(TypeError) { Nymble.nm_credential_create(nm_state, nil, @server_id, @cur_link_window) }
    should.raise(TypeError) { Nymble.nm_credential_create(nm_state, pseudonym, nil, @cur_link_window) }
    should.raise(TypeError) { Nymble.nm_credential_create(nm_state, pseudonym, @server_id, nil) }
    Nymble.nm_credential_create(nm_state, pseudonym, @server_id.reverse, @cur_link_window).should.be.nil
    Nymble.nm_credential_create(nm_state, pseudonym, @server_id, @cur_link_window).should.not.be.nil
  end
  
  it 'should manage USER state' do
    pm_state          = Nymble.pm_initialize(@hmac_key_np)
    nm_state          = Nymble.nm_initialize(@hmac_key_np)
    hmac_key_ns       = Nymble.nm_entry_add(nm_state, @server_id)
    pseudonym, mac_np = Nymble.pm_pseudonym_create(pm_state, @user_id, @cur_link_window)
    blacklist         = Nymble.nm_blacklist_create(nm_state, @server_id, @cur_time_period, @cur_link_window)
    
    Nymble.should.respond_to(:user_initialize)
    should.raise(TypeError) { Nymble.user_initialize(nil, mac_np, Nymble.nm_verify_key(nm_state)) }
    should.raise(TypeError) { Nymble.user_initialize(pseudonym, nil, Nymble.nm_verify_key(nm_state)) }
    should.raise(TypeError) { Nymble.user_initialize(pseudonym, mac_np, nil) }
    
    user_state = Nymble.user_initialize(pseudonym, mac_np, Nymble.nm_verify_key(nm_state))
    user_state.should.not.be.nil
    
    Nymble.should.respond_to(:user_pseudonym)
    should.raise(TypeError) { Nymble.user_pseudonym(nil) }
    Nymble.user_pseudonym(user_state).should.equal(pseudonym)
    
    Nymble.should.respond_to(:user_pseudonym_mac)
    should.raise(TypeError) { Nymble.user_pseudonym_mac(nil) }
    Nymble.user_pseudonym_mac(user_state).should.equal(mac_np)
  end
  
  it 'should allow a SERVER to verify USER credentials' do
    pm_state          = Nymble.pm_initialize(@hmac_key_np)
    nm_state          = Nymble.nm_initialize(@hmac_key_np)
    hmac_key_ns       = Nymble.nm_entry_add(nm_state, @server_id)
    pseudonym, mac_np = Nymble.pm_pseudonym_create(pm_state, @user_id, @cur_link_window)
    credential        = Nymble.nm_credential_create(nm_state, pseudonym, @server_id, @cur_link_window)
    blacklist         = Nymble.nm_blacklist_create(nm_state, @server_id, @cur_time_period, @cur_link_window)
    user_state        = Nymble.user_initialize(pseudonym, mac_np, Nymble.nm_verify_key(nm_state))
    user_state2       = Nymble.user_initialize(pseudonym, mac_np, Nymble.nm_verify_key(nm_state))
    server_state      = Nymble.server_initialize(@server_id, hmac_key_ns, blacklist)
    server_state2     = Nymble.server_initialize(@server_id.reverse, hmac_key_ns, blacklist)
    
    Nymble.should.respond_to(:user_entry_initialize)
    should.raise(TypeError) { Nymble.user_entry_initialize(nil, @server_id, credential) }
    should.raise(TypeError) { Nymble.user_entry_initialize(user_state, nil, credential) }
    should.raise(TypeError) { Nymble.user_entry_initialize(user_state, @server_id, nil) }
    Nymble.user_entry_initialize(user_state, @server_id, credential).should.be(true)
    
    Nymble.should.respond_to(:user_credential_get)
    $L.times do |time_period|
      Nymble.user_credential_get(user_state, @server_id, time_period + 1).should.not.be.nil
    end

    Nymble.should.respond_to(:user_blacklist_update)
    should.raise(TypeError) { Nymble.user_blacklist_update(nil, @server_id, blacklist, @cur_link_window, @cur_time_period) }
    should.raise(TypeError) { Nymble.user_blacklist_update(user_state, nil, blacklist, @cur_link_window, @cur_time_period) }
    should.raise(TypeError) { Nymble.user_blacklist_update(user_state, @server_id, nil, @cur_link_window, @cur_time_period) }
    should.raise(TypeError) { Nymble.user_blacklist_update(user_state, @server_id, blacklist, nil, @cur_time_period) }
    should.raise(TypeError) { Nymble.user_blacklist_update(user_state, @server_id, blacklist, @cur_link_window, nil) }
    Nymble.user_blacklist_update(user_state, @server_id, blacklist, @cur_link_window + 1, @cur_time_period).should.be(false)
    Nymble.user_blacklist_update(user_state, @server_id, blacklist, @cur_link_window, @cur_time_period + 1).should.be(false)
    Nymble.user_blacklist_update(user_state, @server_id, blacklist, @cur_link_window, $L + 1).should.be(false)
    Nymble.user_blacklist_update(user_state2, @server_id, blacklist, @cur_link_window, @cur_time_period).should.be(false)
    Nymble.user_blacklist_update(user_state, @server_id, blacklist, @cur_link_window, @cur_time_period).should.be(true)

    Nymble.should.respond_to(:server_ticket_verify)
    $L.times do |time_period|
      time_period  += 1
      nymble_ticket = Nymble.user_credential_get(user_state, @server_id, time_period)

      should.raise(TypeError) { Nymble.server_ticket_verify(nil, nymble_ticket, @cur_link_window, time_period) }
      should.raise(TypeError) { Nymble.server_ticket_verify(server_state, nil, @cur_link_window, time_period) }
      should.raise(TypeError) { Nymble.server_ticket_verify(server_state, nymble_ticket, nil, time_period) }
      should.raise(TypeError) { Nymble.server_ticket_verify(server_state, nymble_ticket, @cur_link_window, nil) }
      Nymble.server_ticket_verify(server_state, nymble_ticket, @cur_link_window + 1, time_period).should.be(false)
      Nymble.server_ticket_verify(server_state, nymble_ticket, @cur_link_window, time_period + 1).should.be(false)
      Nymble.server_ticket_verify(server_state2, nymble_ticket, @cur_link_window, time_period).should.be(false)
      Nymble.server_ticket_verify(server_state, nymble_ticket, @cur_link_window, time_period).should.be(true)
    end
  end
  
  it 'should allow a SERVER to blacklist a USER' do
    pm_state          = Nymble.pm_initialize(@hmac_key_np)
    nm_state          = Nymble.nm_initialize(@hmac_key_np)
    hmac_key_ns       = Nymble.nm_entry_add(nm_state, @server_id)
    pseudonym, mac_np = Nymble.pm_pseudonym_create(pm_state, @user_id, @cur_link_window)
    credential        = Nymble.nm_credential_create(nm_state, pseudonym, @server_id, @cur_link_window)
    blacklist         = Nymble.nm_blacklist_create(nm_state, @server_id, @cur_time_period, @cur_link_window)
    server_state      = Nymble.server_initialize(@server_id, hmac_key_ns, blacklist)
    user_state        = Nymble.user_initialize(pseudonym, mac_np, Nymble.nm_verify_key(nm_state))
    
    Nymble.user_entry_initialize(user_state, @server_id, credential)
    
    server_state      = Nymble.server_initialize(@server_id, hmac_key_ns, blacklist)
    complaints        = [ Nymble.user_credential_get(user_state, @server_id, @cur_time_period) ]

    Nymble.should.respond_to(:nm_tokens_create)
    should.raise(TypeError) { Nymble.nm_tokens_create(nil, @server_id, blacklist, complaints, @cur_time_period, @cur_link_window) }
    should.raise(TypeError) { Nymble.nm_tokens_create(nm_state, nil, blacklist, complaints, @cur_time_period, @cur_link_window) }
    should.raise(TypeError) { Nymble.nm_tokens_create(nm_state, @server_id, nil, complaints, @cur_time_period, @cur_link_window) }
    should.raise(TypeError) { Nymble.nm_tokens_create(nm_state, @server_id, blacklist, complaints, nil, @cur_link_window) }
    should.raise(TypeError) { Nymble.nm_tokens_create(nm_state, @server_id, blacklist, complaints, @cur_time_period, nil) }
    Nymble.nm_tokens_create(nm_state, @server_id, blacklist, [], @cur_time_period, @cur_link_window).should.not.be.nil

    linking_tokens = Nymble.nm_tokens_create(nm_state, @server_id, blacklist, complaints, @cur_time_period, @cur_link_window)
    linking_tokens.should.not.be.nil
    
    # TODO: test checking linking tokens

    Nymble.should.respond_to(:nm_blacklist_update)
    should.raise(TypeError) { Nymble.nm_blacklist_update(nil, blacklist, complaints, @cur_time_period, @cur_link_window) }
    should.raise(TypeError) { Nymble.nm_blacklist_update(nm_state, nil, complaints, @cur_time_period, @cur_link_window) }
    should.raise(TypeError) { Nymble.nm_blacklist_update(nm_state, blacklist, complaints, nil, @cur_link_window) }
    should.raise(TypeError) { Nymble.nm_blacklist_update(nm_state, blacklist, complaints, @cur_time_period, nil) }

    new_blacklist = Nymble.nm_blacklist_update(nm_state, blacklist, [], @cur_time_period, @cur_link_window)
    new_blacklist.should.not.be.nil

    new_blacklist = Nymble.nm_blacklist_update(nm_state, blacklist, complaints, @cur_time_period, @cur_link_window)
    new_blacklist.should.not.be.nil
    
    Nymble.should.respond_to(:server_update)
    should.raise(TypeError) { Nymble.server_update(nil, blacklist, linking_tokens) }
    should.raise(TypeError) { Nymble.server_update(server_state, nil, linking_tokens) }
    Nymble.server_update(server_state, new_blacklist, linking_tokens).should.be(true)
  end

  it 'should allow a USER to check if it is blacklisted' do
    pm_state          = Nymble.pm_initialize(@hmac_key_np)
    nm_state          = Nymble.nm_initialize(@hmac_key_np)
    hmac_key_ns       = Nymble.nm_entry_add(nm_state, @server_id)
    pseudonym, mac_np = Nymble.pm_pseudonym_create(pm_state, @user_id, @cur_link_window)
    credential        = Nymble.nm_credential_create(nm_state, pseudonym, @server_id, @cur_link_window)
    blacklist         = Nymble.nm_blacklist_create(nm_state, @server_id, @cur_time_period, @cur_link_window)
    server_state      = Nymble.server_initialize(@server_id, hmac_key_ns, blacklist)
    user_state        = Nymble.user_initialize(pseudonym, mac_np, Nymble.nm_verify_key(nm_state))
    Nymble.user_entry_initialize(user_state, @server_id, credential)
    server_state      = Nymble.server_initialize(@server_id, hmac_key_ns, blacklist)
    nymble_ticket     = Nymble.user_credential_get(user_state, @server_id, @cur_time_period)
    complaints        = [ nymble_ticket ]
    new_blacklist     = Nymble.nm_blacklist_update(nm_state, blacklist, complaints, @cur_time_period, @cur_link_window)
    
    Nymble.user_blacklist_update(user_state, @server_id, blacklist, @cur_link_window, @cur_time_period)
    
    Nymble.should.respond_to(:user_blacklist_check)
    Nymble.user_blacklist_check(user_state, @server_id).should.be(false)
    Nymble.user_blacklist_update(user_state, @server_id, new_blacklist, @cur_link_window, @cur_time_period).should.be(true)
    Nymble.user_blacklist_check(user_state, @server_id).should.be(true)
  end

  it 'should actually work' do
    # System parameters
    hmac_key_np     = Nymble.digest('hmac_key_np')
    server_id       = Nymble.digest('server_id')
    user_id         = Nymble.digest('user_id')
    cur_time_period = 1
    cur_link_window = 1
    
    # PM initialize
    pm_state = Nymble.pm_initialize(hmac_key_np)
    
    pm_state.should.not.be.nil
    
    # NM initialize
    nm_state    = Nymble.nm_initialize(hmac_key_np)
    verify_key  = Nymble.nm_verify_key(nm_state)
    
    nm_state.should.not.be.nil
    verify_key.should.not.be.nil
    
    # SERVER initialize
    hmac_key_ns   = Nymble.nm_entry_add(nm_state, server_id)
                    Nymble.nm_entry_update(nm_state, server_id, cur_time_period)
    blacklist     = Nymble.nm_blacklist_create(nm_state, server_id, cur_time_period, cur_link_window)
    server_state  = Nymble.server_initialize(server_id, hmac_key_ns, blacklist)

    server_state.should.not.be.nil
    
    # SERVER update blacklist
    Nymble.server_blacklist_finalized(server_state, cur_time_period).should.be(false)
    
    blacklist = Nymble.server_blacklist(server_state)

    Nymble.nm_entry_exists(nm_state, server_id).should.be(true)
    Nymble.nm_blacklist_verify(nm_state, blacklist, server_id, cur_link_window).should.be(true)

    new_blacklist = Nymble.nm_blacklist_update(nm_state, blacklist, [], cur_time_period, cur_link_window)
                    Nymble.nm_entry_update(nm_state, server_id, cur_time_period)
    
    Nymble.server_update(server_state, new_blacklist, [])
    Nymble.server_iterate(server_state, 1)
    Nymble.server_blacklist_finalize(server_state)
    
    Nymble.server_blacklist_finalized(server_state, cur_time_period).should.be(true)
    
    # USER initialize
    pseudonym, mac_np = Nymble.pm_pseudonym_create(pm_state, user_id, cur_link_window)
    user_state = Nymble.user_initialize(pseudonym, mac_np, verify_key)
    
    user_state.should.not.be.nil
    
    # USER get credential
    Nymble.nm_entry_exists(nm_state, server_id).should.be(true)
    Nymble.nm_pseudonym_verify(nm_state, pseudonym, cur_link_window, mac_np).should.be(true)
    
    credential = Nymble.nm_credential_create(nm_state, pseudonym, server_id, cur_link_window)

    credential.should.not.be.nil
    
    Nymble.user_entry_initialize(user_state, server_id, credential)

    # USER authenticate
    Nymble.user_blacklist_update(user_state, server_id, new_blacklist, cur_link_window, cur_time_period).should.be(true)
    Nymble.user_blacklist_check(user_state, server_id).should.be(false)
    
    ticket = Nymble.user_credential_get(user_state, server_id, cur_time_period)
    
    ticket.should.not.be.nil
    
    Nymble.server_ticket_verify(server_state, ticket, cur_link_window, cur_time_period).should.be(true)

    # time_period change!
    cur_time_period += 1
    Nymble.server_iterate(server_state, 1)
    
    # SERVER complain and update blacklist
    Nymble.server_blacklist_finalized(server_state, cur_time_period).should.be(false)
    
    blacklist   = Nymble.server_blacklist(server_state)
    complaints  = [ ticket ]
    
    Nymble.nm_entry_exists(nm_state, server_id).should.be(true)
    Nymble.nm_blacklist_verify(nm_state, blacklist, server_id, cur_link_window).should.be(true)

    linking_tokens  = Nymble.nm_tokens_create(nm_state, server_id, blacklist, complaints, cur_time_period-1, cur_link_window)
    new_blacklist   = Nymble.nm_blacklist_update(nm_state, blacklist, complaints, cur_time_period, cur_link_window)
                      Nymble.nm_entry_update(nm_state, server_id, cur_time_period)
    
    Nymble.server_update(server_state, new_blacklist, linking_tokens)
    Nymble.server_blacklist_finalize(server_state)
    Nymble.server_blacklist_finalized(server_state, cur_time_period).should.be(true)
    
    # USER authenticate
    Nymble.user_blacklist_update(user_state, server_id, new_blacklist, cur_link_window, cur_time_period).should.be(true)
    Nymble.user_blacklist_check(user_state, server_id).should.be(true)
    
    ticket = Nymble.user_credential_get(user_state, server_id, cur_time_period)
    
    ticket.should.not.be.nil

    Nymble.server_ticket_verify(server_state, ticket, cur_link_window, cur_time_period).should.be(false)
    Nymble.server_ticket_verify(server_state, Nymble.user_credential_get(user_state, server_id, cur_time_period+1), cur_link_window, cur_time_period)#.should.be(false)

    # time_period change!
    cur_time_period += 1
    Nymble.server_iterate(server_state, 1)
    
    # SERVER update blacklist
    Nymble.server_blacklist_finalized(server_state, cur_time_period).should.be(false)
    
    blacklist = Nymble.server_blacklist(server_state)

    Nymble.nm_entry_exists(nm_state, server_id).should.be(true)
    Nymble.nm_blacklist_verify(nm_state, blacklist, server_id, cur_link_window).should.be(true)

    new_blacklist = Nymble.nm_blacklist_update(nm_state, blacklist, [], cur_time_period, cur_link_window)
                    Nymble.nm_entry_update(nm_state, server_id, cur_time_period)
    
    Nymble.server_update(server_state, new_blacklist, [])
    Nymble.server_blacklist_finalize(server_state)
    Nymble.server_blacklist_finalized(server_state, cur_time_period).should.be(true)
    
    # USER authenticate
    Nymble.user_blacklist_update(user_state, server_id, new_blacklist, cur_link_window, cur_time_period).should.be(true)
    Nymble.user_blacklist_check(user_state, server_id).should.be(true)
    
    ticket = Nymble.user_credential_get(user_state, server_id, cur_time_period)
    
    ticket.should.not.be.nil
    
    Nymble.server_ticket_verify(server_state, ticket, cur_link_window, cur_time_period).should.be(false)
  end
end
