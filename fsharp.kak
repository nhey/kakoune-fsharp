# https://fsharp.org/
#

# Detection
# ‾‾‾‾‾‾‾‾‾

hook global BufCreate .*[.](fs|fsx|fsi) %{
    set-option buffer filetype fsharp
}

# Initialization
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾

hook global WinSetOption filetype=fsharp %{
    require-module fsharp

    # cleanup trailing whitespaces upon exiting insert mode
    hook window ModeChange insert:.* -group fsharp-trim-indent %{ try %{ execute-keys -draft \; <a-x> s ^\h+$ <ret> d } }
    # indent on newline
    hook window InsertChar \n -group fsharp-indent fsharp-indent-on-new-line

    hook -once -always window WinSetOption filetype=.* %{ remove-hooks window fsharp-.+ }
}

hook -group fsharp-highlight global WinSetOption filetype=fsharp %{
    add-highlighter window/fsharp ref fsharp
    hook -once -always window WinSetOption filetype=.* %{ remove-highlighter window/fsharp }
}

provide-module fsharp %§

# Highlighters & Completion
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾

add-highlighter shared/fsharp regions
add-highlighter shared/fsharp/code default-region group
add-highlighter shared/fsharp/docstring     region (\(\*) (\*\)) regions
add-highlighter shared/fsharp/double_string region '"'   (?<!\\)(\\\\)*"  fill string
add-highlighter shared/fsharp/comment       region '//'   '$'              fill comment
# https://docs.microsoft.com/en-us/dotnet/fsharp/language-reference/attributes 
add-highlighter shared/fsharp/attributes region "\[<"   ">\]"  fill meta

add-highlighter shared/fsharp/docstring/ default-region fill string
# ability to write highlighted code inside docstring:
add-highlighter shared/fsharp/docstring/ region '>>> \K'    '\z' ref fsharp
add-highlighter shared/fsharp/docstring/ region '\.\.\. \K'    '\z' ref fsharp

evaluate-commands %sh{
    # Grammar
    meta="open"

    # exceptions taken from fsharp.vim colors (https://github.com/fsharp/vim-fsharp)
    exceptions="try|failwith|failwithf|finally|invalid_arg|raise|rethrow"

    # keywords taken from fsharp.vim colors (https://github.com/fsharp/vim-fsharp)
    keywords="abstract|as|assert|base|begin|class|default|delegate"
    keywords="${keywords}|do|done|downcast|downto|elif|else|end|exception"
    keywords="${keywords}|extern|for|fun|function|global|if|in|inherit|inline"
    keywords="${keywords}|interface|lazy|let|match|member|module|mutable"
    keywords="${keywords}|namespace|new|of|override|rec|static|struct|then"
    keywords="${keywords}|to|type|upcast|use|val|void|when|while|with"
    keywords="${keywords}|async|atomic|break|checked|component|const|constraint"
    keywords="${keywords}|constructor|continue|decimal|eager|event|external"
    keywords="${keywords}|fixed|functor|include|method|mixin|object|parallel"
    keywords="${keywords}|process|pure|return|seq|tailcall|trait|yield"
    # additional operator keywords (Microsoft.FSharp.Core.Operators)
    keywords="${keywords}|box|hash|sizeof|typeof|typedefof|unbox|ref|fst|snd"
    keywords="${keywords}|stdin|stdout|stderr"
    # math operators (Microsoft.FSharp.Core.Operators)
    keywords="${keywords}|abs|acos|asin|atan|atan2|ceil|cos|cosh|exp|floor|log"
    keywords="${keywords}|log10|pown|round|sign|sin|sinh|sqrt|tan|tanh"


    types="array|bool|byte|char|decimal|double|enum|exn|float"
    types="${types}|float32|int|int16|int32|int64|lazy_t|list|nativeint"
    types="${types}|obj|option|sbyte|single|string|uint|uint32|uint64"
    types="${types}|uint16|unativeint|unit"

    fsharpCoreMethod="printf|printfn|sprintf|eprintf|eprintfn|fprintf|fprintfn"

    # Add the language's grammar to the static completion list
    printf %s\\n "hook global WinSetOption filetype=fsharp %{
        set-option window static_words ${values} ${meta} ${exceptions} ${keywords} ${types}
    }" | tr '|' ' '

    # Highlight keywords
    printf %s "
        add-highlighter shared/fsharp/code/ regex '\b(${meta})\b' 0:meta
        add-highlighter shared/fsharp/code/ regex '\b(${exceptions})\b' 0:function
        add-highlighter shared/fsharp/code/ regex '\b(${fsharpCoreMethod})\b' 0:function
        add-highlighter shared/fsharp/code/ regex '\b(${keywords})\b' 0:keyword
    "
}

# brackets
add-highlighter shared/fsharp/code/ regex "[\[\]\(\){}]" 0:bracket
# values
add-highlighter shared/fsharp/code/ regex "\b(true|false)\b" 0:value
add-highlighter shared/fsharp/code/ regex "\B(\(\))\B" 0:value
# accomodate typically overloaded operators
add-highlighter shared/fsharp/code/ regex "\B(<<>>|<\|\|>)\B" 0:operator
# fsharp operators
add-highlighter shared/fsharp/code/ regex "\B(->|<-|<=|>=)\B" 0:operator
add-highlighter shared/fsharp/code/ regex "\b(not)\b" 0:operator
add-highlighter shared/fsharp/code/ regex (?<=[\w\s\d'"_])(::|\h\|\h|(\|\|)+|@|\|>|<\||\.\.|<=|>=|<>|(<)+|(>)+|!=|==|(\^)+|(&)+|\+|-|(\*)+|//|/|%|~) 0:operator
add-highlighter shared/fsharp/code/ regex (?<=[\w\s\d'"_])((?<![=<>!])=(?![=])|[+*-]=) 0:builtin

# Commands
# ‾‾‾‾‾‾‾‾

define-command -hidden fsharp-indent-on-new-line %{
    evaluate-commands -draft -itersel %{
        # copy '//' comment prefix and following white spaces
        try %{ execute-keys -draft k <a-x> s ^\h*//\h* <ret> y jgh P }
        # preserve previous line indent
        try %{ execute-keys -draft \; K <a-&> }
        # cleanup trailing whitespaces from previous line
        try %{ execute-keys -draft k <a-x> s \h+$ <ret> d }
        # indent after line ending with =
        try %{ execute-keys -draft <space> k <a-x> <a-k> =$ <ret> j <a-gt> }
        # indent after line ending with "do"
        try %{ execute-keys -draft <space> k <a-x> <a-k> do$ <ret> j <a-gt> }
    }
}

§
