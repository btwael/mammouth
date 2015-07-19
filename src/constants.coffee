module.exports =
    REGEX:
        startTag: /\{\{/
        endTag: /\}\}/

        INDENT: /([\n\r\u2028\u2029][ \t]*)/gm
        LINETERMINATOR: /[\n\r\u2028\u2029]/
        RAWTEXT: /// (
            (
                (
                    ?!(
                        {{
                        |}}
                    )
                )
                ([\n\r\u2028\u2029]|.)
            )*
        ) ///