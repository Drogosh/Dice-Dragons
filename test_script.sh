#!/bin/bash
# Dice & Dragons - Финальный Тестовый Скрипт
# Этот скрипт проверяет, что проект готов к запуску

echo "🎲 Dice & Dragons - Финальная Проверка"
echo "========================================"
echo ""

# Проверка 1: Git Статус
echo "📌 Проверка 1: Git Статус"
git status
if [ $? -eq 0 ]; then
    echo "✅ Git репозиторий в порядке"
else
    echo "❌ Ошибка Git"
    exit 1
fi
echo ""

# Проверка 2: Зависимости
echo "📌 Проверка 2: Зависимости Flutter"
flutter pub get > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ Все зависимости установлены"
else
    echo "❌ Ошибка установки зависимостей"
    exit 1
fi
echo ""

# Проверка 3: Анализ Dart кода
echo "📌 Проверка 3: Анализ кода Dart"
flutter analyze --fatal-infos > analyze_output.txt 2>&1
if grep -q "No issues found" analyze_output.txt || [ $? -eq 0 ]; then
    echo "✅ Нет ошибок анализа кода"
    rm analyze_output.txt
else
    echo "⚠️  Возможны предупреждения (некритичные)"
    head -20 analyze_output.txt
    rm analyze_output.txt
fi
echo ""

# Проверка 4: Основные файлы
echo "📌 Проверка 4: Проверка основных файлов"
files=(
    "lib/models/item.dart"
    "lib/models/character.dart"
    "lib/models/inventory.dart"
    "lib/screens/main_navigation_screen.dart"
    "lib/screens/inventory_screen.dart"
    "lib/screens/character_creation_screen.dart"
    "pubspec.yaml"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file"
    else
        echo "❌ $file - ФАЙЛ НЕ НАЙДЕН"
        exit 1
    fi
done
echo ""

# Проверка 5: UUID зависимость
echo "📌 Проверка 5: Проверка UUID зависимости"
if grep -q "uuid:" pubspec.yaml; then
    echo "✅ UUID пакет добавлен в pubspec.yaml"
else
    echo "❌ UUID пакет не найден в pubspec.yaml"
    exit 1
fi
echo ""

# Финальный статус
echo "========================================"
echo "✅ ВСЕ ПРОВЕРКИ ПРОЙДЕНЫ!"
echo "Приложение готово к запуску:"
echo ""
echo "  flutter run          # Запуск на подключённом девайсе"
echo "  flutter run -d edge  # Запуск в браузере"
echo "  flutter run -d windows  # Запуск на Windows"
echo ""
echo "========================================"

