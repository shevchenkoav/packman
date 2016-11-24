
#Использовать v8runner
#Использовать logos

Перем Лог;

///////////////////////////////////////////////////////////////////////////////////////////////////
// Прикладной интерфейс

Процедура ЗарегистрироватьКоманду(Знач ИмяКоманды, Знач Парсер) Экспорт
    
    ОписаниеКоманды = Парсер.ОписаниеКоманды(ИмяКоманды, "Создание дистрибутива по манифесту EDF");
    // TODO - с помощью tool1cd можно получить из хранилища
    // на больших историях версий получается массивный xml дамп таблицы
    Парсер.ДобавитьПозиционныйПараметрКоманды(ОписаниеКоманды, "ФайлМанифеста", "Путь к манифесту сборки");
    Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, "-out", "Выходной каталог");
    Парсер.ДобавитьПараметрФлагКоманды(ОписаниеКоманды, "-setup", "Собирать дистрибутив вида setup.exe");
    Парсер.ДобавитьПараметрФлагКоманды(ОписаниеКоманды, "-files", "Собирать дистрибутив вида 'файлы поставки'");
    Парсер.ДобавитьКоманду(ОписаниеКоманды);
     
КонецПроцедуры

// Выполняет логику команды
// 
// Параметры:
//   ПараметрыКоманды - Соответствие ключей командной строки и их значений
//
Функция ВыполнитьКоманду(Знач ПараметрыКоманды) Экспорт
    
    Параметры = РазобратьПараметры(ПараметрыКоманды);
    УправлениеКонфигуратором = ОкружениеСборки.ПолучитьКонфигуратор();
    ВыполнитьСборку(
        УправлениеКонфигуратором,
        Параметры.ФайлМанифеста,
        Параметры.СобиратьИнсталлятор,
        Параметры.СобиратьФайлыПоставки,
        Параметры.ВыходнойКаталог);
    
КонецФункции

Процедура ВыполнитьСборку(Знач УправлениеКонфигуратором, Знач ФайлМанифеста, Знач СобиратьИнсталлятор, Знач СобиратьФайлыПоставки, Знач ВыходнойКаталог) Экспорт
    
    Информация = СобратьИнформациюОКонфигурации(УправлениеКонфигуратором);
    СоздатьДистрибутивПоМанифесту(УправлениеКонфигуратором, ФайлМанифеста, Информация.Версия, СобиратьИнсталлятор, СобиратьФайлыПоставки, ВыходнойКаталог);
    
КонецПроцедуры

Функция СобратьИнформациюОКонфигурации(Знач УправлениеКонфигуратором)
    
    Лог.Информация("Запускаю приложение для сбора информации о метаданных");
    
    ФайлДанных = Новый Файл(ОбъединитьПути(УправлениеКонфигуратором.КаталогСборки(), ОкружениеСборки.ИмяФайлаИнформацииОМетаданных()));
    Если ФайлДанных.Существует() Тогда
        УдалитьФайлы(ФайлДанных.ПолноеИмя);
    КонецЕсли;
    
    ОбработкаСборщик = ПутьКОбработкеСборщикуДанных();
    
    УправлениеКонфигуратором.ЗапуститьВРежимеПредприятия(ФайлДанных.ПолноеИмя, Истина, "/Execute""" + ОбработкаСборщик + """");
    
    Возврат ПрочитатьИнформациюОМетаданных(ФайлДанных.ПолноеИмя);
    
КонецФункции

Функция ПутьКОбработкеСборщикуДанных()

    // prod версия
    ОбработкаСборщик = Новый Файл(ОбъединитьПути(ТекущийСценарий().Каталог, "../../СборИнформацииОМетаданных.epf"));
    Если Не ОбработкаСборщик.Существует() Тогда
        Лог.Отладка(СтрШаблон("Не обнаружена обработка сбора данных в каталоге '%1'", ОбработкаСборщик.ПолноеИмя));
    Иначе 
        Возврат ОбработкаСборщик.ПолноеИмя;
    КонецЕсли;

    // dev версия
    ОбработкаСборщик = Новый Файл(ОбъединитьПути(ТекущийСценарий().Каталог, "../../tools/СборИнформацииОМетаданных.epf"));

    Если Не ОбработкаСборщик.Существует() Тогда
        ВызватьИсключение СтрШаблон("Не обнаружена обработка сбора данных в каталоге '%1'", ОбработкаСборщик.ПолноеИмя);
    КонецЕсли;

КонецФункции

Функция ПрочитатьИнформациюОМетаданных(Знач ИмяФайла) Экспорт
    
    Возврат ОкружениеСборки.ПрочитатьИнформациюОМетаданных(ИмяФайла);
    
КонецФункции // ПрочитатьИнформациюОМетаданных()

Функция СоздатьДистрибутивПоМанифесту(
    Знач УправлениеКонфигуратором,
    Знач ФайлМанифеста,
    Знач ВерсияМетаданных,
    Знач СобиратьИнсталлятор,
    Знач СобиратьФайлыПоставки,
    Знач ВыходнойКаталог)
    
    Сборщик = Новый СборщикДистрибутива;
    Сборщик.ФайлМанифеста = ФайлМанифеста;
    Сборщик.СоздаватьИнсталлятор = СобиратьИнсталлятор;
    Сборщик.СоздаватьФайлыПоставки = СобиратьФайлыПоставки;
    Сборщик.ВыходнойКаталог = ВыходнойКаталог; 
    
    Сборщик.Собрать(УправлениеКонфигуратором, ВерсияМетаданных, ВерсияМетаданных);
    
КонецФункции // СоздатьДистрибутивПоМанифесту(Знач УправлениеКонфигуратором, Знач ПараметрыКоманды)

Функция РазобратьПараметры(Знач ПараметрыКоманды) Экспорт
    
    Результат = Новый Структура;
    
    Если ПустаяСтрока(ПараметрыКоманды["ФайлМанифеста"]) Тогда
        ВызватьИсключение "Не задан путь к манифесту сборки (*.edf)";
    КонецЕсли;
    
    Результат.Вставить("ФайлМанифеста", ПараметрыКоманды["ФайлМанифеста"]);
    Результат.Вставить("СобиратьИнсталлятор", ПараметрыКоманды["-setup"]);
    Результат.Вставить("СобиратьФайлыПоставки", ПараметрыКоманды["-files"]);
    Результат.Вставить("ВыходнойКаталог", ПараметрыКоманды["-out"]);
    
    Возврат Результат;
    
КонецФункции

///////////////////////////////////////////////////////////////////////////////////

Лог = Логирование.ПолучитьЛог(ПараметрыСистемы.ИмяЛогаСистемы());
