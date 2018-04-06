interface ParserNotify
  fun ref apply(parser: Parser, token: Token)

class ParserNotifyNone
  fun ref apply(parser: Parser, token: Token) => None
