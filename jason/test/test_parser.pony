use "ponytest"
use ".."

type _TokenData is (Token, USize, USize, I64, F64, String)

class _TestParserNotify is ParserNotify
  let tokens: Array[_TokenData] = []
  
  new ref create() => None
  fun ref apply(parser: Parser, token: Token) =>
    tokens.push((
      token,
      parser.token_start(),
      parser.token_end(),
      try parser.last_number as I64 else 0 end,
      try parser.last_number as F64 else 0 end,
      parser.last_string
    ))

class TestParser is UnitTest
  new iso create() => None
  fun name(): String => "jason.Parser"
  
  fun apply(h: TestHelper) =>
    ///
    // Keywords
    
    example(h, "null",
      [((TokenNull, 0, 4, 0, 0, ""), __loc)])
    example(h, "true",
      [((TokenTrue, 0, 4, 0, 0, ""), __loc)])
    example(h, "false",
      [((TokenFalse, 0, 5, 0, 0, ""), __loc)])
    example(h, " \t\nnull\n\t ",
      [((TokenNull, 3, 7, 0, 0, ""), __loc)])
    
    ///
    // Numbers
    
    example(h, "123", [
      ((TokenNumberPre, 0, 0, 0,   0, ""), __loc)
      ((TokenNumber,    0, 3, 123, 0, ""), __loc)
    ])
    
    example(h, "-123", [
      ((TokenNumberPre, 0, 0, 0,    0, ""), __loc)
      ((TokenNumber,    0, 4, -123, 0, ""), __loc)
    ])
    
    example(h, "123.456", [
      ((TokenNumberPre, 0, 0, 0, 0,       ""), __loc)
      ((TokenNumber,    0, 7, 0, 123.456, ""), __loc)
    ])
    
    example(h, "-123.456", [
      ((TokenNumberPre, 0, 0, 0, 0,        ""), __loc)
      ((TokenNumber,    0, 8, 0, -123.456, ""), __loc)
    ])
    
    example(h, "123e2", [
      ((TokenNumberPre, 0, 0, 0, 0,     ""), __loc)
      ((TokenNumber,    0, 5, 0, 12300, ""), __loc)
    ])
    
    example(h, "-123e-2", [
      ((TokenNumberPre, 0, 0, 0, 0,     ""), __loc)
      ((TokenNumber,    0, 7, 0, -1.23, ""), __loc)
    ])
    
    example(h, "-123.456e2", [
      ((TokenNumberPre, 0, 0,  0, 0,        ""), __loc)
      ((TokenNumber,    0, 10, 0, -12345.6, ""), __loc)
    ])
    
    example(h, "123.456e-2", [
      ((TokenNumberPre, 0, 0,  0, 0,       ""), __loc)
      ((TokenNumber,    0, 10, 0, 1.23456, ""), __loc)
    ])
    
    ///
    // Strings
    
    example(h, """"apple"""", [
      ((TokenStringPre, 1, 1, 0, 0, ""),      __loc)
      ((TokenString,    1, 6, 0, 0, "apple"), __loc)
    ])
    
    example(h, """                    "apple"   """, [
      ((TokenStringPre, 21, 21, 0, 0, ""),      __loc)
      ((TokenString,    21, 26, 0, 0, "apple"), __loc)
    ])
    
    example(h, """                    ""   """, [
      ((TokenStringPre, 21, 21, 0, 0, ""), __loc)
      ((TokenString,    21, 21, 0, 0, ""), __loc)
    ])
    
    example(h, """                    "\b\t\n\f\r\"\/\\"  """, [
      ((TokenStringPre, 21, 21, 0, 0, ""),                __loc)
      ((TokenString,    21, 37, 0, 0, "\b\t\n\f\r\"/\\"), __loc)
    ])
    
    example(h, """"\u0950\ud800\udc00\ud803\ude6d\uDBFF\uDFFF"""", [
      ((TokenStringPre, 1, 1,  0, 0, ""), __loc)
      ((TokenString,    1, 43, 0, 0, "ॐ𐀀𐹭􏿿"), __loc)
    ])
    
    ///
    // Arrays
    
    example(h, "[]", [
      ((TokenArrayStart, 0, 1, 0, 0, ""), __loc)
      ((TokenArrayEnd,   1, 2, 0, 0, ""), __loc)
    ])
    
    example(h, "  [  ]  ", [
      ((TokenArrayStart, 2, 3, 0, 0, ""), __loc)
      ((TokenArrayEnd,   5, 6, 0, 0, ""), __loc)
    ])
    
    example(h, "[1,2,3]", [
      ((TokenArrayStart, 0, 1, 0, 0, ""), __loc)
      ((TokenNumberPre,  1, 1, 0, 0, ""), __loc)
      ((TokenNumber,     1, 2, 1, 0, ""), __loc)
      ((TokenNumberPre,  3, 3, 1, 0, ""), __loc)
      ((TokenNumber,     3, 4, 2, 0, ""), __loc)
      ((TokenNumberPre,  5, 5, 2, 0, ""), __loc)
      ((TokenNumber,     5, 6, 3, 0, ""), __loc)
      ((TokenArrayEnd,   6, 7, 3, 0, ""), __loc)
    ])
    
    example(h, "  [  1  ,  2  ,  3  ]  ", [
      ((TokenArrayStart, 2,  3,  0, 0, ""), __loc)
      ((TokenNumberPre,  5,  5,  0, 0, ""), __loc)
      ((TokenNumber,     5,  6,  1, 0, ""), __loc)
      ((TokenNumberPre,  11, 11, 1, 0, ""), __loc)
      ((TokenNumber,     11, 12, 2, 0, ""), __loc)
      ((TokenNumberPre,  17, 17, 2, 0, ""), __loc)
      ((TokenNumber,     17, 18, 3, 0, ""), __loc)
      ((TokenArrayEnd,   20, 21, 3, 0, ""), __loc)
    ])
    
    example(h, "[[[true]]]", [
      ((TokenArrayStart, 0, 1,  0, 0, ""), __loc)
      ((TokenArrayStart, 1, 2,  0, 0, ""), __loc)
      ((TokenArrayStart, 2, 3,  0, 0, ""), __loc)
      ((TokenTrue,       3, 7,  0, 0, ""), __loc)
      ((TokenArrayEnd,   7, 8,  0, 0, ""), __loc)
      ((TokenArrayEnd,   8, 9,  0, 0, ""), __loc)
      ((TokenArrayEnd,   9, 10, 0, 0, ""), __loc)
    ])
    
    ///
    // Objects
    
    example(h, "{}", [
      ((TokenObjectStart, 0, 1, 0, 0, ""), __loc)
      ((TokenObjectEnd,   1, 2, 0, 0, ""), __loc)
    ])
    
    example(h, "  {  }  ", [
      ((TokenObjectStart, 2, 3, 0, 0, ""), __loc)
      ((TokenObjectEnd,   5, 6, 0, 0, ""), __loc)
    ])
    
    example(h, """{"fruit":"apple","edible":true}""", [
      ((TokenObjectStart, 0,  1,  0, 0, ""),       __loc)
      ((TokenKeyPre,      2,  2,  0, 0, ""),       __loc)
      ((TokenKey,         2,  7,  0, 0, "fruit"),  __loc)
      ((TokenStringPre,   10, 10, 0, 0, "fruit"),  __loc)
      ((TokenString,      10, 15, 0, 0, "apple"),  __loc)
      ((TokenPairPost,    16, 16, 0, 0, "apple"),  __loc)
      ((TokenKeyPre,      18, 18, 0, 0, "apple"),  __loc)
      ((TokenKey,         18, 24, 0, 0, "edible"), __loc)
      ((TokenTrue,        26, 30, 0, 0, "edible"), __loc)
      ((TokenPairPost,    30, 30, 0, 0, "edible"), __loc)
      ((TokenObjectEnd,   30, 31, 0, 0, "edible"), __loc)
    ])
    
    example(h, """  {  "a"  :  1  ,  "b"  :  2  }  """, [
      ((TokenObjectStart, 2,  3,  0, 0, ""),  __loc)
      ((TokenKeyPre,      6,  6,  0, 0, ""),  __loc)
      ((TokenKey,         6,  7,  0, 0, "a"), __loc)
      ((TokenNumberPre,   13, 13, 0, 0, "a"), __loc)
      ((TokenNumber,      13, 14, 1, 0, "a"), __loc)
      ((TokenPairPost,    16, 16, 1, 0, "a"), __loc)
      ((TokenKeyPre,      20, 20, 1, 0, "a"), __loc)
      ((TokenKey,         20, 21, 1, 0, "b"), __loc)
      ((TokenNumberPre,   27, 27, 1, 0, "b"), __loc)
      ((TokenNumber,      27, 28, 2, 0, "b"), __loc)
      ((TokenPairPost,    30, 30, 2, 0, "b"), __loc)
      ((TokenObjectEnd,   30, 31, 2, 0, "b"), __loc)
    ])
    
    example(h, """{"t":[{"e":[{"s":[{"t":[]}]}]}]}""", [
      ((TokenObjectStart, 0,  1,  0, 0, ""),  __loc)
      ((TokenKeyPre,      2,  2,  0, 0, ""),  __loc)
      ((TokenKey,         2,  3,  0, 0, "t"), __loc)
      ((TokenArrayStart,  5,  6,  0, 0, "t"), __loc)
      ((TokenObjectStart, 6,  7,  0, 0, "t"), __loc)
      ((TokenKeyPre,      8,  8,  0, 0, "t"), __loc)
      ((TokenKey,         8,  9,  0, 0, "e"), __loc)
      ((TokenArrayStart,  11, 12, 0, 0, "e"), __loc)
      ((TokenObjectStart, 12, 13, 0, 0, "e"), __loc)
      ((TokenKeyPre,      14, 14, 0, 0, "e"), __loc)
      ((TokenKey,         14, 15, 0, 0, "s"), __loc)
      ((TokenArrayStart,  17, 18, 0, 0, "s"), __loc)
      ((TokenObjectStart, 18, 19, 0, 0, "s"), __loc)
      ((TokenKeyPre,      20, 20, 0, 0, "s"), __loc)
      ((TokenKey,         20, 21, 0, 0, "t"), __loc)
      ((TokenArrayStart,  23, 24, 0, 0, "t"), __loc)
      ((TokenArrayEnd,    24, 25, 0, 0, "t"), __loc)
      ((TokenPairPost,    25, 25, 0, 0, "t"), __loc)
      ((TokenObjectEnd,   25, 26, 0, 0, "t"), __loc)
      ((TokenArrayEnd,    26, 27, 0, 0, "t"), __loc)
      ((TokenPairPost,    27, 27, 0, 0, "t"), __loc)
      ((TokenObjectEnd,   27, 28, 0, 0, "t"), __loc)
      ((TokenArrayEnd,    28, 29, 0, 0, "t"), __loc)
      ((TokenPairPost,    29, 29, 0, 0, "t"), __loc)
      ((TokenObjectEnd,   29, 30, 0, 0, "t"), __loc)
      ((TokenArrayEnd,    30, 31, 0, 0, "t"), __loc)
      ((TokenPairPost,    31, 31, 0, 0, "t"), __loc)
      ((TokenObjectEnd,   31, 32, 0, 0, "t"), __loc)
    ])
    
    ///
    // Keyword Errors
    
    example_error(h, "nugget",    "nu")
    example_error(h, "truth",     "tru")
    example_error(h, "falsehood", "false")
    example_error(h, "bogus",     "")
    
    ///
    // Number Errors
    
    example_error(h, "---",             "-")
    example_error(h, "123456789ABCDEF", "123456789")
    example_error(h, "0x0",             "0")
    example_error(h, "123...",          "123.")
    example_error(h, "123.",            "123.")
    example_error(h, "127.0.0.1",       "127.0")
    example_error(h, "5eed",            "5e")
    example_error(h, "5e---",           "5e-")
    example_error(h, "5e",              "5e")
    example_error(h, "1.2e3.4",         "1.2e3")
    example_error(h, " 1 2 3 ",         " 1 ")
    
    ///
    // String Errors
    
    example_error(h, """ " """,                     """ " """)
    example_error(h, """ "apple""",                 """ "apple""")
    example_error(h, """ "\"""",                    """ "\"""")
    example_error(h, """ "\urge" """,               """ "\u""")
    example_error(h, """ "\u123" """,               """ "\u123""")
    example_error(h, """ "\ud800\n" """,            """ "\ud800\""")
    example_error(h, """ "apple \ud800 banana" """, """ "apple \ud800""")
    example_error(h, """ "\ud800\ud800" """,        """ "\ud800\u""")
    
    ///
    // Array Errors
    
    example_error(h, "]]]",                   "")
    example_error(h, "[[[",                   "[[[")
    example_error(h, "[1,,,]",                "[1,")
    example_error(h, "[1,2,3}",               "[1,2,3")
    example_error(h, """["fruit":"apple"]""", """["fruit"""")
    
    ///
    // Object Errors
    
    example_error(h, "}}}",                    "")
    example_error(h, "{{{",                    "{")
    example_error(h, """{"a":1,,,"b":2}""",    """{"a":1,""")
    example_error(h, """{"a":{"b":""",         """{"a":{"b":""")
    example_error(h, """{"a":1,"b":2]""",      """{"a":1,"b":2""")
    example_error(h, """{"apple","edible"}""", """{"apple"""")
  
  fun example(
    h: TestHelper,
    source: String,
    expected: Array[(_TokenData, SourceLoc)] val,
    loc': SourceLoc = __loc
  ) =>
    let notify = _TestParserNotify
    let parser = Parser
    try
      parser.parse(source, notify)?
      h.assert_eq[USize](notify.tokens.size(), expected.size(), "count", loc')
      try
        for (idx, (token, loc)) in expected.pairs() do
          h.assert_is[Token] (notify.tokens(idx)?._1, token._1, "token",  loc)
          h.assert_eq[USize] (notify.tokens(idx)?._2, token._2, "start",  loc)
          h.assert_eq[USize] (notify.tokens(idx)?._3, token._3, "end",    loc)
          h.assert_eq[I64]   (notify.tokens(idx)?._4, token._4, "I64",    loc)
          h.assert_eq[F64]   (notify.tokens(idx)?._5, token._5, "U64",    loc)
          h.assert_eq[String](notify.tokens(idx)?._6, token._6, "string", loc)
        end
      end
    else
      h.log(parser.describe_error())
      h.assert_no_error({()? => error }, "Couldn't parse: " + source, loc')
    end
  
  fun example_error(
    h: TestHelper,
    source: String,
    valid_part: String,
    loc: SourceLoc = __loc)
  =>
    let parser = Parser
    try
      parser.parse(source)?
      h.assert_error({() => None }, "Expected error parsing: " + source, loc)
    else
      let actual = source.trim(0, parser.token_end())
      h.assert_eq[String](actual, valid_part, "", loc)
    end
