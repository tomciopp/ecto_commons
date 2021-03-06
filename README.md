# EctoCommons

[![Build Status](https://img.shields.io/travis/achedeuzot/ecto_commons/master.svg)](https://travis-ci.org/achedeuzot/ecto_commons) [![Coverage Status](https://coveralls.io/repos/github/achedeuzot/ecto_commons/badge.svg?branch=master)](https://coveralls.io/github/achedeuzot/ecto_commons?branch=master) [![Hex Version](https://img.shields.io/hexpm/v/ecto_commons.svg)](https://hex.pm/packages/ecto_commons) [![License](http://img.shields.io/badge/license-MIT-brightgreen.svg)](http://opensource.org/licenses/MIT)

Ecto common helpers such as validators and formatters.

## Installation

The package is available on [hex](https://hex.pm/), so it can be installed
by adding `ecto_commons` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ecto_commons, "~> 0.1.0"}
  ]
end
```

Documentation is published on [HexDocs](https://hexdocs.pm) and can
be found at [https://hexdocs.pm/ecto_commons](https://hexdocs.pm/ecto_commons).

## Summary

The package contains common ecto helpers:

### Changeset validators
  - `EctoCommon.DateValidator`:
    - `validate_date(changeset, field, opts)`: validates an equality (with
       approximation), before or after a given date.
  - `EctoCommon.DateTimeValidator`
    - `validate_datetime(changeset, field, opts)`: validates an equality (with
       approximation), before or after a given date time.
  - `EctoCommon.TimeValidator`
    - `validate_time(changeset, field, opts)`: validates an equality (with
       approximation), before or after a given time.
  - `EctoCommon.EmailValidator`
    - `validate_email(changeset, field, opts)`: validates emails. As there is no
      perfect validation possible, multiple options are available depending
      on your requirements. Can also reject temporary/burner emails.
  - `EctoCommon.URLValidator`
    - `validate_url(changeset, field, opts)`: validates if an URL is correct. Here
      too, there is no perfection possible. Multiple options are available
      depending on the precision required.
  - `EctoCommon.StringValidator`
    - `validate_has_prefix(changeset, field, opts)`: validates if a string starts
      with a given prefix. The prefix itself can depend on another field or
      on a dynamic value.
  - `EctoCommon.PostalCodeValidator`
    - `validate_postal_code(changeset, field, opts)`: validates postal code formatting
      using regular expressions depending on the country. This only ensures the postal
      code "looks ok" but doesn't check it really exists (that will need a complete
      database of all postal codes worldwide). 
  - `EctoCommon.SocialSecurityValidator`
    - `validate_social_security(changeset, field, opts)`: validates social security
      numbers (SSN) depending on the country. This only validates french SSNs for now.
  - `EctoCommon.LuhnValidator`
    - `validate_luhn(changeset, field, opts)`: validates a string with Luhn's
      algorithm such as credit card numbers and other administrative codes.

## Changeset helpers
 - `EctoCommon.Helpers`
   - `validate_many(changeset, field, opts)`: validates multiple fields with the same
     validation function as well as the same options.

## Changelog

`ecto_commons` follows semantic versioning. See [`CHANGELOG.md`](https://github.com/achedeuzot/ecto_commons/blob/master/CHANGELOG.md) for more information.

## License

MIT. Please see [LICENSE](https://github.com/achedeuzot/ecto_commons/blob/master/LICENSE) for licensing details.
