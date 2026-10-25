require ["fileinto", "mailbox", "variables", "regex", "envelope", "relational", "comparator-i;ascii-numeric", "copy"];

set "to" "";
set "local" "";
set "domain" "";

if anyof(
  header :value "ge" :comparator "i;ascii-numeric" "X-Spam-score" "5",
  header :contains "X-Spam" "Yes"
) {
  fileinto :create "Junk";
  stop;
}

if header :contains ["X-Delivered-To", "X-Original-Delivered-To", "Delivered-To"] "interactivebrokerskaryna@ivanchenko.io" {
  redirect :copy "karyna@ivanchenko.io";
}

if header :regex "X-Forwarded-For" "^([^ ]+)" {
  set "to" "${1}";
} elsif header :matches "X-Original-Delivered-To" "*" {
  set "to" "${1}";
} elsif header :matches "X-Delivered-To" "*" {
  set "to" "${1}";
} elsif envelope :matches "to" "*" {
  set "to" "${1}";
}

if string :regex "${to}" "^([^@]+)@([^@]+)$" {
  set :lower "local" "${1}";
  set :lower "domain" "${2}";

  if string :is "${domain}" "ivanchenko.io" {
    if string :regex "${local}" "^([^.]*)\\.?([^.]*)\\.?([^.]*)\\.?([^.]*)$" {
      set "local" "${1}${2}${3}${4}";
    }
  }

  fileinto :create "${domain}/${local}";
  stop;
}
