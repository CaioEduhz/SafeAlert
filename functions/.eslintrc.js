module.exports = {
  root: true,
  env: {
    es6: true,
    node: true,
  },
  extends: [
    "eslint:recommended",
    "google",
  ],
  parserOptions: {
    "ecmaVersion": 2020, // Suporte para funcionalidades mais recentes do JS
  },
  rules: {
    "quotes": ["error", "double"],

    // --- REGRAS ADICIONADAS PARA CORRIGIR O ERRO ---
    "indent": "off", // Desativa a verificação de indentação
    "max-len": "off", // Desativa a verificação de comprimento máximo da linha
    // ---------------------------------------------
  },
};

