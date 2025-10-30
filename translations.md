# Rename Honeypot Files Plan

## Step 1: Rename English Folder Files

Rename files in `honeypot_files/English/` to descriptive titles based on content:

- `contract_1.txt` → `Software_Licensing_Agreement.txt`
- `contract_2.txt` → `Non_Disclosure_Agreement.txt`
- `password_hashes.txt` → `Password_Hashes.txt` (keep as-is)
- `passwords.txt` → `Passwords.txt` (keep as-is)
- `research_doc_1.txt` → `Quantum_Computing_Vulnerabilities.txt`
- `research_doc_2.txt` → `Next_Generation_Encryption.txt`
- `research_doc_3.txt` → `AI_Intrusion_Detection_Systems.txt`
- `speech_1.txt` → `Security_Audit_Briefing.txt`
- `speech_2.txt` → `Data_Protection_Initiatives.txt`

## Step 2: Rename Russian Folder Files

Rename files in `honeypot_files/Russian/` to Russian (Cyrillic) titles based on content:

- `contract_1.txt` → `Лицензионный_договор_ПО.txt`
- `contract_2.txt` → `Соглашение_о_неразглашении.txt`
- `password_hashes.txt` → `Хэши_паролей.txt`
- `passwords.txt` → `Пароли.txt`
- `research_doc_1.txt` → `Квантовые_угрозы_безопасности.txt`
- `research_doc_2.txt` → `Методы_шифрования_нового_поколения.txt`
- `research_doc_3.txt` → `Системы_обнаружения_вторжений_ИИ.txt`
- `speech_1.txt` → `Отчет_аудита_безопасности.txt`
- `speech_2.txt` → `Инициативы_защиты_данных.txt`

## Step 3: Rename Chinese Folder Files

Rename files in `honeypot_files/Chinese/` to Chinese (Simplified) titles:

- `contract_1.txt` → `软件许可协议.txt`
- `contract_2.txt` → `保密协议.txt`
- `password_hashes.txt` → `密码哈希.txt`
- `passwords.txt` → `密码.txt`
- `research_doc_1.txt` → `量子计算漏洞.txt`
- `research_doc_2.txt` → `下一代加密技术.txt`
- `research_doc_3.txt` → `人工智能入侵检测系统.txt`
- `speech_1.txt` → `安全审计简报.txt`
- `speech_2.txt` → `数据保护举措.txt`

## Step 4: Rename French Folder Files

Rename files in `honeypot_files/French/` to French titles:

- `contract_1.txt` → `Accord_de_licence_logicielle.txt`
- `contract_2.txt` → `Accord_de_confidentialité.txt`
- `password_hashes.txt` → `Hachages_de_mots_de_passe.txt`
- `passwords.txt` → `Mots_de_passe.txt`
- `research_doc_1.txt` → `Vulnérabilités_informatique_quantique.txt`
- `research_doc_2.txt` → `Chiffrement_nouvelle_génération.txt`
- `research_doc_3.txt` → `Systèmes_détection_intrusion_IA.txt`
- `speech_1.txt` → `Briefing_audit_sécurité.txt`
- `speech_2.txt` → `Initiatives_protection_données.txt`

## Step 5: Rename Hebrew Folder Files

Rename files in `honeypot_files/Hebrew/` to Hebrew titles:

- `contract_1.txt` → `הסכם_רישוי_תוכנה.txt`
- `contract_2.txt` → `הסכם_סודיות.txt`
- `password_hashes.txt` → `גיבובי_סיסמאות.txt`
- `passwords.txt` → `סיסמאות.txt`
- `research_doc_1.txt` → `פגיעויות_מחשוב_קוונטי.txt`
- `research_doc_2.txt` → `הצפנה_דור_הבא.txt`
- `research_doc_3.txt` → `מערכות_גילוי_חדירות_AI.txt`
- `speech_1.txt` → `תדריך_ביקורת_אבטחה.txt`
- `speech_2.txt` → `יוזמות_הגנת_מידע.txt`

## Step 6: Rename Spanish Folder Files

Rename files in `honeypot_files/Spanish/` to Spanish titles:

- `contract_1.txt` → `Acuerdo_licencia_software.txt`
- `contract_2.txt` → `Acuerdo_confidencialidad.txt`
- `password_hashes.txt` → `Hashes_contraseñas.txt`
- `passwords.txt` → `Contraseñas.txt`
- `research_doc_1.txt` → `Vulnerabilidades_computación_cuántica.txt`
- `research_doc_2.txt` → `Cifrado_nueva_generación.txt`
- `research_doc_3.txt` → `Sistemas_detección_intrusiones_IA.txt`
- `speech_1.txt` → `Informe_auditoría_seguridad.txt`
- `speech_2.txt` → `Iniciativas_protección_datos.txt`

## Step 7: Rename Ukrainian Folder Files

Rename files in `honeypot_files/Ukrainian/` to Ukrainian titles:

- `contract_1.txt` → `Ліцензійна_угода_ПЗ.txt`
- `contract_2.txt` → `Угода_про_нерозголошення.txt`
- `password_hashes.txt` → `Хеші_паролів.txt`
- `passwords.txt` → `Паролі.txt`
- `research_doc_1.txt` → `Вразливості_квантових_обчислень.txt`
- `research_doc_2.txt` → `Шифрування_нового_покоління.txt`
- `research_doc_3.txt` → `Системи_виявлення_вторгнень_ШІ.txt`
- `speech_1.txt` → `Звіт_аудиту_безпеки.txt`
- `speech_2.txt` → `Ініціативи_захисту_даних.txt`

## Implementation

Use PowerShell `Rename-Item` or `Move-Item` commands to rename each file while preserving content. Files will be renamed in two-step process: first English and Russian (as requested), then other languages when their content is ready.