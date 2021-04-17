module.exports = {
    printWidth: 100,
    tabWidth: 4,
    trailingComma: 'es5',
    singleQuote: true,
    overrides: [
        {
            files: '*.cmp',
            options: {
                printWidth: 160,
                tabWidth: 2,
                trailingComma: 'none',
            },
        },

        {
            files: '*.css',
            options: {
                singleQuote: false,
            },
        },
        {
            files: '**/lwc/**/*.html',
            options: {
                printWidth: 160,
                tabWidth: 2,
                parser: 'lwc',
            },
        },
        {
            files: '*.{cmp,page,component}',
            options: { parser: 'html' },
        },
    ],
};
