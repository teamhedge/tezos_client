# frozen_string_literal: true

require "base58"
require "rbnacl"
require "digest"

class TezosClient
  module Crypto
    using StringUtils

    PREFIXES = {
      tz1:    [6, 161, 159],
      tz2:    [6, 161, 161],
      tz3:    [6, 161, 164],
      KT:     [2, 90, 121],
      edpk:   [13, 15, 37, 217],
      edsk2:  [13, 15, 58, 7],
      spsk:   [17, 162, 224, 201],
      p2sk:   [16, 81, 238, 189],
      sppk:   [3, 254, 226, 86],
      p2pk:   [3, 178, 139, 127],
      edsk:   [43, 246, 78, 7],
      edsig:  [9, 245, 205, 134, 18],
      spsig1: [13, 115, 101, 19, 63],
      p2sig:  [54, 240, 44, 52],
      sig:    [4, 130, 43],
      Net:    [87, 82, 0],
      nce:    [69, 220, 169],
      b:      [1, 52],
      o:      [5, 116],
      Lo:     [133, 233],
      LLo:    [29, 159, 109],
      P:      [2, 170],
      Co:     [79, 179],
      id:     [153, 103]
    }.freeze

    WATERMARK = {
      block: "01",
      endorsement: "02",
      generic: "03"
    }.freeze

    def hex_prefix(type)
      PREFIXES[type].pack("C*").to_hex
    end

    def decode_base58(base58_val)
      bin_val = Base58.base58_to_binary(base58_val, :bitcoin)
      bin_val.to_hex
    end

    def encode_base58(hex_val)
      bin_val = hex_val.to_bin
      Base58.binary_to_base58(bin_val, :bitcoin)
    end

    def checksum(hex)
      b = hex.to_bin
      Digest::SHA256.hexdigest(Digest::SHA256.digest(b))[0...8]
    end

    def get_prefix_and_payload(str)
      PREFIXES.keys.each do |prefix|
        if str.start_with? hex_prefix(prefix)
          return prefix, str[(hex_prefix(prefix).size) .. -1]
        end
      end
    end

    def decode_tz(str)
      decoded = decode_base58 str

      unless checksum(decoded[0...-8]) != decoded[0...-8]
        raise "invalid checksum for #{str}"
      end

      prefix, payload = get_prefix_and_payload(decoded[0...-8])

      yield(prefix, payload) if block_given?

      payload
    end

    def encode_tz(prefix, str)
      prefixed = hex_prefix(prefix) + str
      checksum = checksum(prefixed)

      encode_base58(prefixed + checksum)
    end

    def secret_key_to_public_key(secret_key)
      signing_key = signing_key(secret_key)
      verify_key = signing_key.verify_key
      hex_pubkey = verify_key.to_s.to_hex

      encode_tz(:edpk, hex_pubkey)
    end

    def public_key_to_address(public_key)
      public_key = decode_tz(public_key) do |type, _key|
        raise "invalid public key: #{public_key} " unless type == :edpk
      end

      hash = RbNaCl::Hash::Blake2b.digest(public_key, digest_size: 20)
      hex_hash = hash.to_hex

      encode_tz(:tz1, hex_hash)
    end

    def generate_key
      signing_key = RbNaCl::SigningKey.generate.to_bytes.to_hex

      secret_key = encode_tz(:edsk2, signing_key)
      public_key = secret_key_to_public_key(secret_key)
      address = public_key_to_address(public_key)

      {
        secret_key: secret_key,
        public_key: public_key,
        address: address
      }
    end

    def signing_key(secret_key)
      secret_key = decode_tz(secret_key) do |type, _key|
        raise "invalid secret key: #{secret_key} " unless type == :edsk2
      end

      RbNaCl::SigningKey.new(secret_key.to_bin)
    end

    def sign_bytes(secret_key:, data:, watermark: nil)
      watermarked_data = if watermark.nil?
        data
      else
        WATERMARK[watermark] + data
      end

      hash = RbNaCl::Hash::Blake2b.digest(watermarked_data.to_bin, digest_size: 32)

      signing_key = signing_key(secret_key)
      bin_signature = signing_key.sign(hash)

      edsig = encode_tz(:edsig, bin_signature.to_hex)
      signed_data = data + bin_signature.to_hex

      if block_given?
        yield(edsig, signed_data)
      else
        edsig
      end
    end

    def operation_id(signed_operation_hex)
      hash = RbNaCl::Hash::Blake2b.digest(
        signed_operation_hex.to_bin,
        digest_size: 32
      )
      encode_tz(:o, hash.to_hex)
    end


    def sign_operation(secret_key:, operation_hex:)
      sign_bytes(secret_key: secret_key,
                 data: operation_hex,
                 watermark: :generic) do |edsig, signed_data|
        op_id = operation_id(signed_data)

        if block_given?
          yield(edsig, signed_data, op_id)
        else
          edsig
        end
      end
    end
  end
end
