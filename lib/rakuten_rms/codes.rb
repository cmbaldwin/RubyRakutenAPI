# frozen_string_literal: true

module RakutenRms
  # Named constants for the numeric codes RMS expects in *requests*, so callers
  # can write +status: :awaiting_confirmation+ instead of +status: [100]+.
  #
  # Response-side enumerations (carrier code, card pay type, ...) are not mapped:
  # they arrive as numbers in the raw order hash and are the caller's to read.
  module Codes
    # +orderProgress+ / +orderProgressList+ — the order's lifecycle stage.
    ORDER_PROGRESS = {
      awaiting_confirmation: 100,         # 注文確認待ち
      rakuten_processing: 200,            # 楽天処理中
      awaiting_shipment: 300,             # 発送待ち
      awaiting_change_confirmation: 400,  # 変更確定待ち
      shipped: 500,                       # 発送済
      payment_processing: 600,            # 支払手続き中
      payment_completed: 700,             # 支払手続き済
      awaiting_cancellation: 800,         # キャンセル確定待ち
      cancelled: 900                      # キャンセル確定
    }.freeze

    # +dateType+ — which timestamp +searchOrder+ filters on.
    DATE_TYPE = {
      ordered: 1,            # 注文日
      confirmed: 2,          # 注文確認日
      fixed: 3,              # 注文確定日
      shipped: 4,            # 発送日
      shipping_reported: 5,  # 発送完了報告日
      payment_fixed: 6       # 決済確定日
    }.freeze

    # +deliveryClass+ — the temperature band shown to the customer.
    DELIVERY_CLASS = {
      none: 0,        # 選択なし
      normal: 1,      # 普通
      chilled: 2,     # 冷蔵
      frozen: 3,      # 冷凍
      other_1: 4,
      other_2: 5,
      other_3: 6,
      other_4: 7,
      other_5: 8
    }.freeze

    # +shippingTerm+ — requested delivery time slot. Custom ranges are sent as
    # +h1h2+ integers (1416 == 14:00-16:00), which callers pass through as-is.
    SHIPPING_TERM = {
      none: 0,       # なし
      morning: 1,    # 午前
      afternoon: 2,  # 午後
      other: 9       # その他
    }.freeze

    # +deliveryCompany+ — carrier codes, as of RakutenPayOrderAPI 7.9 (2025/06).
    DELIVERY_COMPANY = {
      other: "1000",                  # その他
      yamato: "1001",                 # ヤマト運輸
      sagawa: "1002",                 # 佐川急便
      japan_post: "1003",             # 日本郵便
      seino: "1004",                  # 西濃運輸
      seino_super_express: "1005",    # セイノースーパーエクスプレス
      fukuyama: "1006",               # 福山通運
      nx_transport: "1015",           # NXトランスポート
      rakuten_express: "1028",        # Rakuten EXPRESS
      japan_post_rakuten: "1029",     # 日本郵便 楽天倉庫出荷
      yamato_yu_packet: "1030",       # ヤマト運輸 クロネコゆうパケット
      meitetsu_nx: "1031"             # 名鉄NX運輸
    }.freeze

    class << self
      # Resolve one symbol (or an already-numeric code) against a table.
      #
      # @param table [Hash] one of the constants above
      # @param value [Symbol, String, Integer] symbolic name or literal code
      # @raise [ArgumentError] if a symbol is not in the table
      def resolve(table, value)
        return value unless value.is_a?(Symbol)

        table.fetch(value) do
          raise ArgumentError, "unknown code #{value.inspect}, expected one of: #{table.keys.join(', ')}"
        end
      end

      # Resolve a scalar or array into an array of literal codes.
      def resolve_all(table, values)
        Array(values).map { |value| resolve(table, value) }
      end
    end
  end
end
