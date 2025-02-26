#!/usr/bin/env bats

load test_helper

setup() {
  global_setup
  [[ -f "$DOKKU_ROOT/VHOST" ]] && cp -fp "$DOKKU_ROOT/VHOST" "$DOKKU_ROOT/VHOST.bak"
  create_app
}

teardown() {
  destroy_app
  [[ -f "$DOKKU_ROOT/VHOST.bak" ]] && mv "$DOKKU_ROOT/VHOST.bak" "$DOKKU_ROOT/VHOST" && chown dokku:dokku "$DOKKU_ROOT/VHOST"
  global_teardown
}

@test "(domains) domains:help" {
  run /bin/bash -c "dokku domains"
  echo "output: $output"
  echo "status: $status"
  assert_output_contains "Manage domains used by the proxy"
  help_output="$output"

  run /bin/bash -c "dokku domains:help"
  echo "output: $output"
  echo "status: $status"
  assert_output_contains "Manage domains used by the proxy"
  assert_output "$help_output"
}

@test "(domains) domains" {
  run /bin/bash -c "dokku domains:report $TEST_APP 2>/dev/null | grep ${TEST_APP}.${DOKKU_DOMAIN}"
  echo "output: $output"
  echo "status: $status"
  assert_output_contains "${TEST_APP}.${DOKKU_DOMAIN}"
}

@test "(domains) domains:add" {
  run /bin/bash -c "dokku domains:add $TEST_APP www.test.app.${DOKKU_DOMAIN}"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "dokku domains:add $TEST_APP 2.app.${DOKKU_DOMAIN}"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "dokku domains:add $TEST_APP a--domain.with--hyphens"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "dokku domains:add $TEST_APP .${DOKKU_DOMAIN}"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "dokku domains:add $TEST_APP _"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "dokku domains:report $TEST_APP 2>/dev/null"
  echo "output: $output"
  echo "status: $status"
  assert_success
  assert_output_contains "www.test.app.${DOKKU_DOMAIN}"
  assert_output_contains "2.app.${DOKKU_DOMAIN}"
  assert_output_contains a--domain.with--hyphens
  assert_output_contains _
}

@test "(domains) domains:add (multiple)" {
  run /bin/bash -c "dokku domains:add $TEST_APP www.test.app.${DOKKU_DOMAIN} 2.app.${DOKKU_DOMAIN} a--domain.with--hyphens"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "dokku domains:report $TEST_APP 2>/dev/null"
  echo "output: $output"
  echo "status: $status"
  assert_success
  assert_output_contains "www.test.app.${DOKKU_DOMAIN}"
  assert_output_contains "2.app.${DOKKU_DOMAIN}"
  assert_output_contains a--domain.with--hyphens
}

@test "(domains) domains:add (duplicate)" {
  run /bin/bash -c "dokku domains:add $TEST_APP test.app.${DOKKU_DOMAIN}"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "dokku domains:add $TEST_APP test.app.${DOKKU_DOMAIN}"
  echo "output: $output"
  echo "status: $status"
  assert_success
}

@test "(domains) domains:add (invalid)" {
  run /bin/bash -c "dokku domains:add $TEST_APP http://test.app.${DOKKU_DOMAIN}"
  echo "output: $output"
  echo "status: $status"
  assert_failure
}

@test "(domains) domains:remove" {
  run /bin/bash -c "dokku domains:add $TEST_APP test.app.${DOKKU_DOMAIN}"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "dokku domains:remove $TEST_APP test.app.${DOKKU_DOMAIN}"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "dokku domains:report $TEST_APP 2>/dev/null"
  echo "output: $output"
  echo "status: $status"
  assert_success
  assert_output_contains "test.app.${DOKKU_DOMAIN}" 0
}

@test "(domains) domains:remove (multiple)" {
  run /bin/bash -c "dokku domains:add $TEST_APP www.test.app.${DOKKU_DOMAIN} test.app.${DOKKU_DOMAIN} 2.app.${DOKKU_DOMAIN}"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "dokku domains:remove $TEST_APP www.test.app.${DOKKU_DOMAIN} test.app.${DOKKU_DOMAIN}"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "dokku domains:report $TEST_APP 2>/dev/null"
  echo "output: $output"
  echo "status: $status"
  assert_success
  assert_output_contains "www.test.app.${DOKKU_DOMAIN}" 0
  assert_output_contains "test.app.${DOKKU_DOMAIN}" 0
  assert_output_contains "2.app.${DOKKU_DOMAIN}"
}

@test "(domains) domains:remove (wildcard domain)" {
  run /bin/bash -c "dokku domains:add $TEST_APP '*.${DOKKU_DOMAIN}'"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "dokku domains:report $TEST_APP --domains-app-vhosts"
  echo "output: $output"
  echo "status: $status"
  assert_success
  assert_output "$TEST_APP.${DOKKU_DOMAIN} *.${DOKKU_DOMAIN}"

  run /bin/bash -c "dokku domains:remove $TEST_APP '*.${DOKKU_DOMAIN}'"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "dokku domains:report $TEST_APP --domains-app-vhosts"
  echo "output: $output"
  echo "status: $status"
  assert_success
  assert_output "$TEST_APP.${DOKKU_DOMAIN}"
}

@test "(domains) domains:set" {
  run /bin/bash -c "dokku domains:add $TEST_APP www.test.app.${DOKKU_DOMAIN} test.app.${DOKKU_DOMAIN}"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "dokku domains:set $TEST_APP 2.app.${DOKKU_DOMAIN} a--domain.with--hyphens"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "dokku domains:report $TEST_APP 2>/dev/null"
  echo "output: $output"
  echo "status: $status"
  assert_success
  assert_output_contains "www.test.app.${DOKKU_DOMAIN}" 0
  assert_output_contains "test.app.${DOKKU_DOMAIN}" 0
  assert_output_contains "2.app.${DOKKU_DOMAIN}"
  assert_output_contains a--domain.with--hyphens
}

@test "(domains) domains:reset" {
  run /bin/bash -c "dokku domains:add $TEST_APP test.app.${DOKKU_DOMAIN}"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "dokku domains:report $TEST_APP"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "dokku domains:reset $TEST_APP"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "dokku domains:report $TEST_APP 2>/dev/null"
  echo "output: $output"
  echo "status: $status"
  assert_success
  assert_output_contains "test.app.${DOKKU_DOMAIN}" 0
}

@test "(domains) domains:add-global" {
  run /bin/bash -c "dokku domains:add-global global.${DOKKU_DOMAIN}"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "dokku domains:report --global"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "dokku domains:report 2>/dev/null | grep -qw 'global.${DOKKU_DOMAIN}'"
  echo "output: $output"
  echo "status: $status"
  assert_success
}

@test "(domains) domains:add-global (multiple)" {
  run /bin/bash -c "dokku domains:add-global global1.${DOKKU_DOMAIN} global2.${DOKKU_DOMAIN} global3.${DOKKU_DOMAIN}"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "dokku domains:report 2>/dev/null | grep -q global1.${DOKKU_DOMAIN}"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "dokku domains:report 2>/dev/null | grep -q global2.${DOKKU_DOMAIN}"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "dokku domains:report 2>/dev/null | grep -q global3.${DOKKU_DOMAIN}"
  echo "output: $output"
  echo "status: $status"
  assert_success
}

@test "(domains) domains:clear-global" {
  run /bin/bash -c "dokku domains:add-global global.dokku.invalid"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "dokku domains:add-global global.${DOKKU_DOMAIN}"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "dokku domains:clear-global"
  echo "output: $output"
  echo "status: $status"
  assert_success
  refute_line "global.dokku.invalid"
  refute_line "global.${DOKKU_DOMAIN}"
}

@test "(domains) domains:remove-global" {
  run /bin/bash -c "dokku domains:add-global global.${DOKKU_DOMAIN}"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "dokku domains:remove-global global.${DOKKU_DOMAIN}"
  echo "output: $output"
  echo "status: $status"
  refute_line "global.${DOKKU_DOMAIN}"
}

@test "(domains) domains (multiple global domains)" {
  run /bin/bash -c "dokku domains:add-global global1.${DOKKU_DOMAIN} global2.${DOKKU_DOMAIN}"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run destroy_app
  echo "output: $output"
  echo "status: $status"
  assert_success

  run create_app
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "dokku domains:report $TEST_APP 2>/dev/null"
  echo "output: $output"
  echo "status: $status"
  assert_success
  assert_output_contains "${TEST_APP}.global1.${DOKKU_DOMAIN}"
  assert_output_contains "${TEST_APP}.global2.${DOKKU_DOMAIN}"
}

@test "(domains) domains:set-global" {
  run /bin/bash -c "dokku domains:add-global global1.${DOKKU_DOMAIN} global2.${DOKKU_DOMAIN}"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "dokku domains:set-global global3.${DOKKU_DOMAIN} global4.${DOKKU_DOMAIN}"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run destroy_app
  echo "output: $output"
  echo "status: $status"
  assert_success

  run create_app
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "dokku domains:report $TEST_APP 2>/dev/null"
  echo "output: $output"
  echo "status: $status"
  assert_success
  assert_output_contains "${TEST_APP}.global1.${DOKKU_DOMAIN}" 0
  assert_output_contains "${TEST_APP}.global2.${DOKKU_DOMAIN}" 0
  assert_output_contains "${TEST_APP}.global3.${DOKKU_DOMAIN}"
  assert_output_contains "${TEST_APP}.global4.${DOKKU_DOMAIN}"
}

@test "(domains) app name overlaps with global domain.tld" {
  run /bin/bash -c "dokku domains:set-global dokku.test"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "dokku --quiet apps:create test.dokku.test"
  echo "output: $output"
  echo "status: $status"
  assert_success

  # run domains:clear in order to invoke default vhost creation
  run /bin/bash -c "dokku --quiet domains:clear test.dokku.test"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "dokku domains:report test.dokku.test --domains-app-vhosts"
  echo "output: $output"
  echo "status: $status"
  assert_success
  assert_output "test.dokku.test"

  run /bin/bash -c "dokku --force apps:destroy test.dokku.test"
  echo "output: $output"
  echo "status: $status"
  assert_success
}

@test "(domains) app rename only renames domains associated with global domains" {
  run /bin/bash -c "dokku domains:set-global ${DOKKU_DOMAIN}"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "dokku domains:set $TEST_APP $TEST_APP.${DOKKU_DOMAIN} $TEST_APP.dokku.test"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "dokku apps:rename $TEST_APP other-name"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "dokku domains:report other-name --domains-app-vhosts"
  echo "output: $output"
  echo "status: $status"
  assert_success
  assert_output "other-name.${DOKKU_DOMAIN} $TEST_APP.dokku.test"

  run /bin/bash -c "dokku apps:rename other-name $TEST_APP"
  echo "output: $output"
  echo "status: $status"
  assert_success
}

@test "(domains) verify warning on ipv4/ipv6 domain name" {
  touch /etc/nginx/sites-enabled/default
  rm "$DOKKU_ROOT/VHOST"
  echo "127.0.0.1" >"$DOKKU_ROOT/VHOST"
  run deploy_app
  echo "output: $output"
  echo "status: $status"
  assert_success
  assert_output_contains "Detected IPv4 domain name with nginx proxy enabled."

  rm -f /etc/nginx/sites-enabled/default
  run /bin/bash -c "dokku ps:rebuild $TEST_APP"
  echo "output: $output"
  echo "status: $status"
  assert_success
  assert_output_contains "Detected IPv4 domain name with nginx proxy enabled." 0
}
