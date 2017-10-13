#Использовать v8runner
#Использовать cmdline
#Использовать logos
#Использовать 1commands
#Использовать strings

Перем ВозможныеКоманды;
Перем Лог;
Перем ЭтоWindows;

Процедура ИнициализацияОкружения()

	НачалоВыполнения = ТекущаяДата();
	СистемнаяИнформация = Новый СистемнаяИнформация;
	ЭтоWindows = Найти(ВРег(СистемнаяИнформация.ВерсияОС), "WINDOWS") > 0;

	Лог = Логирование.ПолучитьЛог("oscript.app.vanessa-init");
	Лог.УстановитьРаскладку(ЭтотОбъект);
	УровеньЛога = УровниЛога.Информация;
	РежимРаботы = ПолучитьПеременнуюСреды("RUNNER_ENV");
	Если ЗначениеЗаполнено(РежимРаботы) И РежимРаботы = "debug" Тогда
		УровеньЛога = УровниЛога.Отладка;
	КонецЕсли;
	
	Лог.УстановитьУровень(УровеньЛога);

	Парсер = Новый ПарсерАргументовКоманднойСтроки();
	Лог1 = Логирование.ПолучитьЛог("oscript.lib.cmdline");
	Лог1.УстановитьУровень(УровеньЛога);
	
	Парсер.ДобавитьИменованныйПараметр("--sha", "Версия sha1 для синхронизации", Истина); //
	Парсер.ДобавитьПараметрФлаг("--force", "Принудительная синхронизация", Истина);

	ОписаниеКоманды = Парсер.ОписаниеКоманды("sync");
	Парсер.ДобавитьКоманду(ОписаниеКоманды);
	
	Аргументы = Парсер.РазобратьКоманду(АргументыКоманднойСтроки);

	Если Аргументы = Неопределено Тогда
		Аргументы = Новый Структура("Команда, ЗначенияПараметров", "sync", Новый Соответствие);
	КонецЕсли;

	Версия = Аргументы.ЗначенияПараметров["--sha"];
	
	Команда = Новый Команда;
	КомандныйФайл = Новый КомандныйФайл;
	КомандныйФайл.УстановитьКодировкуВывода(КодировкаТекста.UTF8);
	
	КаталогРабочейКопии = "./build/vanessa-behavior";
	АдресРепо = "https://github.com/silverbulleters/vanessa-behavior.git";
	СоздатьКаталог(КаталогРабочейКопии);

	ИмяФайлаКоммита = ПолучитьИмяВременногоФайла("txt");
	ИмяФайлаЛога = ПолучитьИмяВременногоФайла("txt");

	ПрефиксЭкспортаПеременной = ?(ЭтоWindows, "set", "export");
	Если ЭтоWindows Тогда
		КомандныйФайл.ДобавитьКоманду("cd /d " + ОбернутьВКавычки(КаталогРабочейКопии));
	Иначе
		КомандныйФайл.ДобавитьКоманду("cd " + ОбернутьВКавычки(КаталогРабочейКопии));
	КонецЕсли;
	КомандныйФайл.ДобавитьКоманду("git init .");
	КомандныйФайл.ДобавитьКоманду(СтрШаблон("git fetch --tags --progress %1 +refs/heads/*:refs/remotes/origin/*", АдресРепо));
	КомандныйФайл.ДобавитьКоманду(СтрШаблон("git config remote.origin.url %1", АдресРепо));
	КомандныйФайл.ДобавитьКоманду("git config --add remote.origin.fetch +refs/heads/*:refs/remotes/origin/*");
	КомандныйФайл.ДобавитьКоманду(СтрШаблон("git config remote.origin.url %1", АдресРепо));
	КомандныйФайл.ДобавитьКоманду(СтрШаблон("git fetch --tags --progress %1 +refs/heads/*:refs/remotes/origin/*", АдресРепо));
	КомандныйФайл.ДобавитьКоманду("git checkout -f "+Версия);
	КомандныйФайл.ДобавитьКоманду("git clean -fd");
	КомандныйФайл.ДобавитьКоманду("git show -s "+Версия+ " > "+ОбернутьВКавычки(ИмяФайлаКоммита));
	//КомандныйФайл.ДобавитьКоманду("git log > "+ОбернутьВКавычки(ИмяФайлаЛога));
	

	Если Не ЭтоWindows Тогда
		КомандныйФайл.ДобавитьКоманду("exit $#");
	Иначе
		// сейчас аккуратно верну кодировку, 
		// иначе после выполнения коммита все последующие команды скриптов будут неверно отображаться в консоли!
		КомандныйФайл.ДобавитьКоманду("set gitsync_exit=%ERRORLEVEL%");
		КомандныйФайл.ДобавитьКоманду("chcp 866 >nul");// >nul важен для исключения ненужной надписи с иероглифами
		КомандныйФайл.ДобавитьКоманду("exit /b %gitsync_exit%");
	КонецЕсли;

	ИмяФайлаВыполнения = КомандныйФайл.Закрыть();

	Если Лог.Уровень() = УровниЛога.Отладка Тогда
		текстФайла = "";
		Если ПолучитьТекстФайла(ИмяФайлаВыполнения, текстФайла) Тогда
			Лог.Отладка("ВыполнитьКоммитГит: текст файла запуска "+Символы.ВК+текстФайла);
		Иначе
			Лог.Ошибка("ВыполнитьКоммитГит: не удалось вывести текст пакетного файла");
		КонецЕсли;
	КонецЕсли;

	рез = КомандныйФайл.Исполнить();

	текстФайла = "";
	ПолучитьТекстФайла(ИмяФайлаКоммита, текстФайла);
	
	текстЛога = "";
	СтрокаЗапуска = "git log -n 200";
	ВыводПроцесса = ЗапуститьИПодождатьБезВывода(СтрокаЗапуска);
	текстЛога = ВыводПроцесса.Результат;
	
	force = Аргументы.ЗначенияПараметров["--force"];
	
	УдалитьФайлы(ИмяФайлаКоммита);
	УдалитьФайлы(ИмяФайлаЛога);
	ПозицияВЛоге = СтрНайти(текстЛога, Версия);
	Если ПозицияВЛоге > 0 Тогда
		Лог.Информация("Версия уже есть разобранная "+Версия +" позиция:" + ПозицияВЛоге);
		Лог.Информация(Сред(текстЛога, ?(ПозицияВЛоге > 200, ПозицияВЛоге - 200, 0), 600));
		Если force = Ложь Тогда
			Возврат;
		КонецЕсли;
	КонецЕсли;

	Лог.Информация("Парсим файл информации");
	Информация = РаспарситьИнформациюОбКоммите(текстФайла);


	СоздатьКаталог("./build/vanessa-behavior/epf");
	Лог.Информация("Перемещаем файлы");
	ПереместитьФайл("./build/vanessa-behavior/vanessa-behavior.epf", "./build/vanessa-behavior/epf/vanessa-behavior.epf");
	Попытка
			ПереместитьФайл("./build/vanessa-behavior/vbFeatureReader.epf", "./build/vanessa-behavior/epf/vbfeaturereader.epf");

	Исключение
	КонецПопытки;

	Если НЕ Новый Файл("./build/ib").Существует() Тогда
		СтрокаВыполнения = "oscript ./tools/init.os init-dev --src ./lib/CF/83NoSync";
		Лог.Информация(СтрокаВыполнения);
		Команда.УстановитьСтрокуЗапуска(СтрокаВыполнения);
		Команда.Исполнить();

		СтрокаВыполнения = "oscript ./tools/init.os init-dev --dev --src ./lib/CF/83NoSync";
		Лог.Информация(СтрокаВыполнения);
		Команда.УстановитьСтрокуЗапуска(СтрокаВыполнения);
		Команда.Исполнить();
	КонецЕсли;

	Команда = Новый Команда;
	Команда.УстановитьПравильныйКодВозврата(0);
	
	МассивФайловДляПеремещения = Новый Массив();
	МассивФайловДляПеремещения.Добавить("features");
	МассивФайловДляПеремещения.Добавить("epf");
	МассивФайловДляПеремещения.Добавить("vendor");
	МассивФайловДляПеремещения.Добавить("spec");
	МассивФайловДляПеремещения.Добавить("plugins");
	МассивФайловДляПеремещения.Добавить("locales");
	МассивФайловДляПеремещения.Добавить("license");
	
	МассивФайловДляПеремещения.Добавить("lib");
	МассивФайловДляПеремещения.Добавить("examples");
	МассивФайловДляПеремещения.Добавить("doc");

	СоответствиеНрег = Новый Соответствие;
	//СоответствиеНрег.Вставить("features", Истина);
	//СоответствиеНрег.Вставить("vendor", Истина);
	//СоответствиеНрег.Вставить("epf", Истина);
	//СоответствиеНрег.Вставить("examples", Истина);

	Для Каждого Элемент из СоответствиеНрег Цикл
		ПеревестиФайлыВНижнийРегистр(СтрШаблон("./build/vanessa-behavior/%1", Элемент.Ключ));
	КонецЦикла;

	
	Для каждого Элемент из МассивФайловДляПеремещения Цикл
		//ПеревестиФайлыВНижнийРегистр(СтрШаблон("./build/vanessa-behavior/%1", Элемент));
		УдалитьФайлы(СтрШаблон("./%1", Элемент));
		СоздатьКаталог(СтрШаблон("./%1", Элемент));
		СтрокаВыполнения = СтрШаблон("oscript ./tools/runner.os decompileepf ./build/vanessa-behavior/%1 ./%1", Элемент);
		Лог.Информация(СтрокаВыполнения);
		ЗапуститьИПодождать(СтрокаВыполнения);
		//Команда.УстановитьСтрокуЗапуска(СтрокаВыполнения);
		//Команда.Исполнить();

		УдалитьФайлы(СтрШаблон("./build/vanessa-behavior/%1", Элемент));
	КонецЦикла;

	ВыполнитьДействияВКлонеИЗакомитеть(КаталогРабочейКопии, Информация);

	Лог.Информация("==============================================");
	Лог.Информация(Строка(НачалоВыполнения) +" - "+Строка(ТекущаяДата()));

КонецПроцедуры


Процедура ВыполнитьДействияВКлонеИЗакомитеть(КаталогКопии, ПараметрыКоммита)
	
	Комментарий = ПараметрыКоммита.Сообщение;
	ИмяФайлаКомментария = ВременныеФайлы.СоздатьФайл("txt");
	ФайлКомментария = Новый ЗаписьТекста(ИмяФайлаКомментария, КодировкаТекста.UTF8NoBOM);
	ФайлКомментария.Записать(Комментарий);
	ФайлКомментария.Закрыть();
	Лог.Информация("Текст коммита: <"+Комментарий+">");

	УдалитьФайлы("./", "*.log");

	СтрокаЗапуска = "git status";
	ВыводПроцесса = ЗапуститьИПодождать(СтрокаЗапуска);
	Приостановить(1000);

	//Удалим изменения толстых форм, если там не было изменений модуля формы. 
	СтрокаЗапуска = "git diff --name-status HEAD";
	ВыводПроцесса = ЗапуститьИПодождать(СтрокаЗапуска);
	ЖурналИзмененийГит = ВыводПроцесса.Результат;
	МассивИмен = Новый Массив;
	МассивСтрокЖурнала = СтроковыеФункции.РазложитьСтрокуВМассивПодстрок(ЖурналИзмененийГит, Символы.ПС);
	Для Каждого СтрокаЖурнала Из МассивСтрокЖурнала Цикл
		Лог.Отладка("	<%1>", СтрокаЖурнала);
		СтрокаЖурнала = СокрЛ(СтрокаЖурнала);
		СимволИзменений = Лев(СтрокаЖурнала, 1);
		Если СимволИзменений = "M" Тогда
			ИмяФайла = СокрЛП(Сред(СтрокаЖурнала, 2));
			// ИмяФайла = СтрЗаменить(ИмяФайла, Символ(0), "");
			МассивИмен.Добавить(ИмяФайла);
			Лог.Отладка("		В журнале git найдено имя файла <%1>", ИмяФайла);
		КонецЕсли;
	КонецЦикла;

	Для каждого Элемент из МассивИмен Цикл
		Если Прав(Элемент, 8) = "Form.bin" Тогда
			ЧастьПути = Лев(Элемент, СтрДлина(Элемент)-8);
			Лог.Информация(ЧастьПути);
			ПутьМодуляФормы = ЧастьПути + "Form/Module.bsl";
			Если СтрНайти(ЖурналИзмененийГит, ПутьМодуляФормы) = 0 Тогда
				ЗапуститьИПодождать("git checkout -- "+Элемент);
				Приостановить(2000);
				ЗапуститьИПодождать("git checkout -- "+ЧастьПути);
				Приостановить(2000);
			КонецЕсли;
		КонецЕсли;
	КонецЦикла;

	КомандныйФайл = Новый КомандныйФайл;
	
	КомандныйФайл.УстановитьКодировкуВывода(КодировкаТекста.UTF8);

	ПрефиксЭкспортаПеременной = ?(ЭтоWindows, "set", "export");
	КомандныйФайл.ДобавитьКоманду(ПрефиксЭкспортаПеременной + "  GIT_AUTHOR_DATE="+ОбернутьВКавычки(ПараметрыКоммита.Дата));
	КомандныйФайл.ДобавитьКоманду(ПрефиксЭкспортаПеременной + " GIT_COMMITTER_DATE="+ОбернутьВКавычки(ПараметрыКоммита.Дата));
	КомандныйФайл.ДобавитьКоманду(СтрШаблон("git add -A ."));

	Автор = ПараметрыКоммита.Автор;
	
	КомандаКоммита = СтрШаблон("git commit -a --file=""%1"" --author=""%2"" ", ИмяФайлаКомментария, Автор);
	
	КомандныйФайл.ДобавитьКоманду(КомандаКоммита);

	Если Не ЭтоWindows Тогда
		КомандныйФайл.ДобавитьКоманду("exit $#");
	Иначе		
		// сейчас аккуратно верну кодировку, 
		// иначе после выполнения коммита все последующие команды скриптов будут неверно отображаться в консоли!
		КомандныйФайл.ДобавитьКоманду("set gitsync_exit=%ERRORLEVEL%");
		КомандныйФайл.ДобавитьКоманду("chcp 866 >nul");// >nul важен для исключения ненужной надписи с иероглифами
		КомандныйФайл.ДобавитьКоманду("exit /b %gitsync_exit%");
	КонецЕсли;

	ИмяФайлаВыполнения = КомандныйФайл.Закрыть();

	Если Лог.Уровень() = УровниЛога.Отладка Тогда
		текстФайла = "";
		Если ПолучитьТекстФайла(ИмяФайлаВыполнения, текстФайла) Тогда
			Лог.Отладка("ВыполнитьКоммитГит: текст файла запуска "+Символы.ВК+текстФайла);
		Иначе
			Лог.Ошибка("ВыполнитьКоммитГит: не удалось вывести текст пакетного файла");
		КонецЕсли;
	КонецЕсли;

	Приостановить(3000);
	рез = КомандныйФайл.Исполнить();

	Лог.Информация("ВыполнитьКоммитГит: Вызов git commit вернул код <" + рез + "> ");

	ВыводКоманды = КомандныйФайл.ПолучитьВывод();
	Если рез <> 0 Тогда
		Лог.Ошибка("ВыполнитьКоммитГит: Лог неудачной команды git commit %1%2", Символы.ПС, ВыводКоманды);
	Иначе
		Лог.Отладка("ВыполнитьКоммитГит: Лог команды git commit %1%2", Символы.ПС, ВыводКоманды);
	КонецЕсли;

	Если Рез <> 0 Тогда
		ВызватьИсключение "Коммит в git выполнить не удалось. См. лог";
	КонецЕсли;

КонецПроцедуры

Процедура ПеревестиФайлыВНижнийРегистр(КаталогРабочейКопии)

	КаталогВанессы = Новый Файл(КаталогРабочейКопии);
	МассивДляУдаления = Новый Массив();
	МассивФайлов = НайтиФайлы(КаталогРабочейКопии, "*.*", Ложь);
	Для каждого Элемент из МассивФайлов Цикл
		ПутьКФайлу = СтрЗаменить(Элемент.ПолноеИмя, КаталогВанессы.ПолноеИмя, "");
		КаталогФайла = СтрЗаменить(Новый Файл(Элемент.ПолноеИмя).Путь, КаталогВанессы.ПолноеИмя, "");
		Если Лев(ПутьКФайлу, 1) = "/" ИЛИ Лев(ПутьКФайлу, 1) = "\" Тогда
			ПутьКФайлу = Сред(ПутьКФайлу, 2);
		КонецЕсли;
		Если Лев(КаталогФайла, 1) = "/" или Лев(КаталогФайла, 1) = "\" Тогда
			КаталогФайла = Сред(КаталогФайла, 2);
		КонецЕсли;

		Если Элемент.ЭтоФайл() Тогда
			//КаталогФайла = СтрЗаменить(Элемент.Путь, КаталогВанессы.ПолноеИмя, "");
			Если Нрег(ПутьКФайлу) <> ПутьКФайлу Тогда
				Если ЗначениеЗаполнено(СокрЛП(КаталогФайла)) Тогда
					//Сообщить(ОбъединитьПути(КаталогВанессы.ПолноеИмя, Нрег(КаталогФайла)));
					СоздатьКаталог(ОбъединитьПути(КаталогВанессы.ПолноеИмя, Нрег(КаталогФайла)));
				КонецЕсли;
				НовоеИмя = ОбъединитьПути(КаталогВанессы.ПолноеИмя, Нрег(ПутьКФайлу));
				//Лог.Отладка("ПутьКФайлу:"+ПутьКФайлу + " новое:"+НовоеИмя);
				//МассивДляУдаления.Добавить(Элемент.ПолноеИмя);
				ПереместитьФайл(Элемент.ПолноеИмя, НовоеИмя);
			КонецЕсли;
		ИначеЕсли Элемент.ЭтоКаталог() Тогда
			НовоеИмя = ОбъединитьПути(КаталогВанессы.ПолноеИмя, Нрег(ПутьКФайлу));
			Если НРег(ПутьКФайлу) <> ПутьКФайлу Тогда
				//Если ЭтоWindows Тогда
				НовоеИмя = ОбъединитьПути(КаталогВанессы.ПолноеИмя, Нрег(ПутьКФайлу));
				ПереместитьФайл(Элемент.ПолноеИмя, НовоеИмя);
				//Лог.Отладка("ПутьККаталогу:"+ПутьКФайлу + " новое:"+НовоеИмя);
				//СоздатьКаталог(ОбъединитьПути(КаталогВанессы.ПолноеИмя, Нрег(ПутьКФайлу)));
				//МассивДляУдаления.Добавить(Элемент.ПолноеИмя);
			КонецЕсли;
			ПеревестиФайлыВНижнийРегистр(НовоеИмя);
		КонецЕсли;
	КонецЦикла;

	Для каждого Элемент из МассивДляУдаления Цикл
		Попытка
			УдалитьФайлы(Элемент);
		Исключение
		КонецПопытки;
	КонецЦикла;

КонецПроцедуры

Функция РаспарситьИнформациюОбКоммите(текстФайла)
	Перем Результат;
	Результат = Новый Структура("Автор, Дата, Сообщение", "", "", "");
	Сообщение = "";
	ВерсияКоммита = "";
	МассивСтрок = СтроковыеФункции.РазложитьСтрокуВМассивПодстрок(текстФайла, Символы.ПС);
	Сообщить(МассивСтрок.Количество());
	Строка = МассивСтрок.Получить(1);
	Результат.Вставить("Автор", СокрЛП(Сред(Строка, 8)));
	
	Строка = МассивСтрок.Получить(2);
	Результат.Вставить("Дата", СокрЛП(Сред(Строка, 6)));
	
	НашлиСообщениеКоммита = Ложь;
	Для Сч = 1 По МассивСтрок.ВГраница() Цикл
		Строка = МассивСтрок.Получить(Сч);
		Если НашлиСообщениеКоммита = Ложь Тогда
			Если СтрНайти(Строка, "Author:") > 0 Тогда
				Результат.Вставить("Автор", СокрЛП(Сред(Строка, 8)));
				Продолжить;
			ИначеЕсли СтрНайти(Строка, "Date:") > 0 Тогда 
				Результат.Вставить("Дата", СокрЛП(Сред(Строка, 6)));
				НашлиСообщениеКоммита = Истина;
				Продолжить;
			КонецЕсли;
			Продолжить;
		КонецЕсли;
		Строка = МассивСтрок.Получить(Сч);
		Разделитель = ?(ЗначениеЗаполнено(Сообщение), Символы.ПС, "");
		Сообщение = Сообщение + Разделитель + СокрЛП(Строка);
	КонецЦикла;

	Сообщение = Сообщение + Символы.ПС + МассивСтрок.Получить(0);

	Результат.Вставить("Сообщение", Сообщение);

	Для каждого Элемент Из Результат Цикл
		Сообщить(Элемент.Ключ + ":"+Элемент.Значение);
	КонецЦикла;

	Возврат Результат;

КонецФункции
	
Функция ОбернутьВКавычки(Знач Строка)
	Возврат """" + Строка + """";
КонецФункции

Функция ПолучитьТекстФайла(ИмяФайла, резТекстФайла = "")

	// проверим есть ли файл
	Файл = Новый Файл(ИмяФайла);
	Если НЕ Файл.Существует() Тогда
		Лог.Информация("Файл не существует."+ИмяФайла);
		Возврат Ложь;
	КонецЕсли;

	Кодировка = "utf-8";

	ФайлОтчета = Новый ЧтениеТекста(ИмяФайла, Кодировка);
	МассивСтрок = Новый Массив;

	Попытка
		Стр = "";
		Пока Стр <> Неопределено Цикл
			Стр = ФайлОтчета.ПрочитатьСтроку();
			МассивСтрок.Добавить(Стр);
		КонецЦикла;
		ФайлОтчета.Закрыть();
	Исключение
		Лог.Ошибка("При выводе файла возникла ошибка: %1", ОписаниеОшибки());
		Возврат Ложь;
	КонецПопытки;
	Если МассивСтрок.Количество() = 0 Тогда
		Лог.Информация("Файл пуст."+ИмяФайла);
		Возврат Ложь;
	КонецЕсли;

	Лог.Отладка("В файле найдено <"+МассивСтрок.Количество()+"> строк."+ИмяФайла);
	// вывести если строки не нашлись
	//текстФайла = "+---/ "+ИмяФайла+" /-------------------------------";
	текстФайла = "";
	Для Инд = 0 По МассивСтрок.ВГраница() Цикл
		Разделитель = ?(Инд = 0, "", Символы.ПС);
		текстФайла = текстФайла + Разделитель + МассивСтрок[Инд];
	КонецЦикла;
	//текстФайла = текстФайла + Символы.ПС + "+-------------";
	резТекстФайла = текстФайла;

	Возврат Истина;
КонецФункции

Процедура ЗапуститьСозданиеСервернойБазы(Параметры)
		Команда = Новый Команда;

		СИ = Новый СистемнаяИнформация;
		СоответствиеПеременных = Новый Соответствие();
		СоответствиеПеременных.Вставить("RUNNER_srvr", "--srvr");
		СоответствиеПеременных.Вставить("RUNNER_srvrport", "--srvrport");
		СоответствиеПеременных.Вставить("RUNNER_srvrproto", "--srvrproto");
		СоответствиеПеременных.Вставить("RUNNER_ref", "--ref");
		СоответствиеПеременных.Вставить("RUNNER_dbms", "--dbms");
		СоответствиеПеременных.Вставить("RUNNER_dbsrvr", "--dbsrvr");
		СоответствиеПеременных.Вставить("RUNNER_dbname", "--dbname");
		СоответствиеПеременных.Вставить("RUNNER_dbuid", "--dbuid");
		СоответствиеПеременных.Вставить("RUNNER_dbpwd", "--dbpwd");
		СоответствиеПеременных.Вставить("RUNNER_locale", "--locale");
		СоответствиеПеременных.Вставить("RUNNER_crsqldb", "--crsqldb");
		СоответствиеПеременных.Вставить("RUNNER_schjobdn", "--schjobdn");
		СоответствиеПеременных.Вставить("RUNNER_susr", "--susr");
		СоответствиеПеременных.Вставить("RUNNER_spwd", "--spwd");
		СоответствиеПеременных.Вставить("RUNNER_licdstr", "--licdstr");
		СоответствиеПеременных.Вставить("RUNNER_zn", "--zn");
		
		ПодключитьСценарий(ОбъединитьПути(ТекущийСценарий().Каталог, "..", "tools", "runner.os"), "runner");
		runner = Новый runner();
		runner.ДополнитьАргументыИзПеременныхОкружения(Параметры, СоответствиеПеременных);

		Параметры["--srvrport"] = ЗначениеПоУмолчанию(Параметры["--srvrport"], Строка(1541));
		Параметры["--srvrproto"] = ЗначениеПоУмолчанию(Параметры["--srvrproto"], "tcp://");
		Параметры["--dbms"] = ЗначениеПоУмолчанию(Параметры["--dbms"], "PostgreSQL");
		Параметры["--locale"] = ЗначениеПоУмолчанию(Параметры["--locale"], "ru");
		Параметры["--dbname"] = ЗначениеПоУмолчанию(Параметры["--dbname"], Параметры["--ref"]);
		Параметры["--crsqldb"] = ЗначениеПоУмолчанию(Параметры["--crsqldb"], "Y");
		Параметры["--licdstr"] = ЗначениеПоУмолчанию(Параметры["--licdstr"], "Y");
		Параметры["--schjobdn"] = ЗначениеПоУмолчанию(Параметры["--schjobdn"], "N");

		Параметры["--srvr"] = ?(
			ЗначениеЗаполнено(СИ.ПолучитьПеременнуюСреды("SERVERONEC")),
			СИ.ПолучитьПеременнуюСреды("SERVERONEC"),
			Параметры["--srvr"]);
		Параметры["--ref"] = ?(
			ЗначениеЗаполнено(СИ.ПолучитьПеременнуюСреды("SERVERBASE")),
			СИ.ПолучитьПеременнуюСреды("SERVERBASE"),
			Параметры["--ref"]);
		Параметры["--ref"] = ?(
			ЗначениеЗаполнено(СИ.ПолучитьПеременнуюСреды("SERVERBASE")),
			СИ.ПолучитьПеременнуюСреды("SERVERBASE"),
			Параметры["--ref"]);
		Параметры["--dbsrvr"] = ?(
			ЗначениеЗаполнено(СИ.ПолучитьПеременнуюСреды("SERVERPOSTGRES")),
			СИ.ПолучитьПеременнуюСреды("SERVERPOSTGRES"),
			Параметры["--dbsrvr"]);
		
		Параметры["--dbuid"] = ?(
			ЗначениеЗаполнено(СИ.ПолучитьПеременнуюСреды("SERVERPOSTGRESUSER")),
			СИ.ПолучитьПеременнуюСреды("SERVERPOSTGRESUSER"),
			Параметры["--dbuid"]);
		
		Параметры["--dbpwd"] = ?(
			ЗначениеЗаполнено(СИ.ПолучитьПеременнуюСреды("SERVERPOSTGRESPASSWD")),
			СИ.ПолучитьПеременнуюСреды("SERVERPOSTGRESPASSWD"),
			Параметры["--dbpwd"]);

		Параметры["--srvr"] = ЗначениеПоУмолчанию(Параметры["--srvr"], "serveronec.service.consul");
		Параметры["--srvr"] = ЗначениеПоУмолчанию(Параметры["--srvr"], "dev");
		Параметры["--dbsrvr"] = ЗначениеПоУмолчанию(Параметры["--dbsrvr"], "postgres");
		Параметры["--dbuid"] = ЗначениеПоУмолчанию(Параметры["--dbuid"], "postgres");
		Параметры["--dbpwd"] = ЗначениеПоУмолчанию(Параметры["--dbpwd"], "postgres");

		СтрокаПодключенияСервера = "" + Параметры["--srvrproto"] + Параметры["--srvr"] + ":" + Строка(Параметры["--srvrport"]);
		СтрокаСозданияБазы = "";
		
		СтрокаСозданияБазы = СтрШаблон("Srvr=%1;Ref=%2", 
				СтрокаПодключенияСервера,
				Параметры["--ref"]
				);
		СтрокаСозданияБазы = СтрШаблон("%1;DBMS=%2", 
				СтрокаСозданияБазы, 
				Параметры["--dbms"]
			);
		СтрокаСозданияБазы = СтрШаблон("%1;DBSrvr=%2;DB=%3",
			СтрокаСозданияБазы,
			Параметры["--dbsrvr"],
			Параметры["--dbname"]);
	
		Если ЗначениеЗаполнено(Параметры["--dbuid"]) Тогда 
			СтрокаСозданияБазы = СтрШаблон("%1;DBUID=%2", СтрокаСозданияБазы, Параметры["--dbuid"]);
			Если ЗначениеЗаполнено(Параметры["--dbpwd"]) Тогда
				СтрокаСозданияБазы = СтрШаблон("%1;DBPwd=%2", СтрокаСозданияБазы, Параметры["--dbpwd"]);
			КонецЕсли;
		КонецЕсли;

		Если Параметры["--dbms"] = "MSSQLServer" Тогда
			СтрокаСозданияБазы = СтрШаблон("%1;SQLYOffs=%2", СтрокаСозданияБазы, "2000");
		КонецЕсли;

		СтрокаСозданияБазы = СтрШаблон("%1;Locale=%2", СтрокаСозданияБазы, Параметры["--locale"]);
		СтрокаСозданияБазы = СтрШаблон("%1;CrSQLDB=Y", СтрокаСозданияБазы);
		СтрокаСозданияБазы = СтрШаблон("%1;SchJobDn=%2", СтрокаСозданияБазы, Параметры["--schjobdn"]);
		Если ЗначениеЗаполнено(Параметры["--susr"]) Тогда 
			СтрокаСозданияБазы = СтрШаблон("%1;SUsr=%2", СтрокаСозданияБазы, Параметры["--susr"]);
			Если ЗначениеЗаполнено(Параметры["--spwd"]) Тогда
				СтрокаСозданияБазы = СтрШаблон("%1;SPwd=%2", СтрокаСозданияБазы, Параметры["--spwd"]);
			КонецЕсли;
		КонецЕсли;

		Аргументы = Новый Структура();
		Аргументы.Вставить("Команда", "server");
		Аргументы.Вставить("ЗначенияПараметров", Параметры);
		runner.ОпределитьПараметрыРаботы(Аргументы);

		Конфигуратор = Новый УправлениеКонфигуратором();
		//Логирование.ПолучитьЛог("oscript.lib.v8runner").УстановитьУровень(Лог.Уровень());

		ВерсияПлатформы = Аргументы.ЗначенияПараметров["--v8version"];
		Если ЗначениеЗаполнено(ВерсияПлатформы) Тогда
			Лог.Отладка("ИнициализацироватьБазуДанных ВерсияПлатформы:"+ВерсияПлатформы);
			Конфигуратор.ИспользоватьВерсиюПлатформы(ВерсияПлатформы);
		КонецЕсли;

		ПараметрыЗапуска = Новый Массив;
		ПараметрыЗапуска.Добавить("CREATEINFOBASE");
		
		//Лог.Отладка(СтрокаСозданияБазы);
		Если НЕ ЭтоWindows Тогда
			СтрокаСозданияБазы = """"+СтрокаСозданияБазы+"""";
			СтрокаСозданияБазы = СтрЗаменить(СтрокаСозданияБазы, """", "\""");
			СтрокаСозданияБазы = СтрЗаменить(СтрокаСозданияБазы,  ";", "\;");
		КонецЕсли;
		Лог.Отладка(СтрокаСозданияБазы);

		ПараметрыЗапуска.Добавить(СтрокаСозданияБазы);
		ПараметрыЗапуска.Добавить("/L"+Параметры["--locale"]);
		ПараметрыЗапуска.Добавить("/Out""" +Конфигуратор.ФайлИнформации() + """");

		СтрокаЗапуска = "";
		СтрокаДляЛога = "";
		Для Каждого Параметр Из ПараметрыЗапуска Цикл
			СтрокаЗапуска = СтрокаЗапуска + " " + Параметр;
		КонецЦикла;

		Приложение = "";
		Приложение = Конфигуратор.ПутьКПлатформе1С();
		Если Найти(Приложение, " ") > 0 Тогда 
			Приложение = runner.ОбернутьПутьВКавычки(Приложение);
		КонецЕсли;
		СтрокаЗапуска = Приложение + " "+СтрокаЗапуска;
		Сообщить(СтрокаЗапуска);
		
		ЗаписьXML = Новый ЗаписьXML();
		ЗаписьXML.УстановитьСтроку();

		Процесс = СоздатьПроцесс(СтрокаЗапуска, "./", Истина, Истина);
		Процесс.Запустить();
		Процесс.ОжидатьЗавершения();
		ЗаписьXML.ЗаписатьБезОбработки(Процесс.ПотокВывода.Прочитать());
		РезультатРаботыПроцесса = ЗаписьXML.Закрыть();
		Сообщить(РезультатРаботыПроцесса);

		РезультатСообщение = ПрочитатьФайлИнформации(Конфигуратор.ФайлИнформации());
		Если НЕ (СтрНайти(РезультатСообщение, "успешно завершено") > 0 ИЛИ СтрНайти(РезультатСообщение, "completed successfully") > 0) Тогда
			ВызватьИсключение "Результат работы не успешен: " + Символы.ПС + РезультатСообщение; 
		КонецЕсли;

		Попытка
			УдалитьФайлы(Конфигуратор.ФайлИнформации());
		Исключение
		КонецПопытки;

		Параметры = Аргументы.ЗначенияПараметров;

КонецПроцедуры

Функция ПрочитатьФайлИнформации(Знач ПутьКФайлу)

	Текст = "";
	Файл = Новый Файл(ПутьКФайлу);
	Если Файл.Существует() Тогда
		Чтение = Новый ЧтениеТекста(Файл.ПолноеИмя);
		Текст = Чтение.Прочитать();
		Чтение.Закрыть();
	Иначе
		Текст = "Информации об ошибке нет";
	КонецЕсли;

	Лог.Отладка("файл информации:
	|"+Текст);
	Возврат Текст;

КонецФункции


Функция ЗначениеПоУмолчанию(value, defValue="")
	res = ?( ЗначениеЗаполнено(value), value, defValue);
	Возврат res;
КонецФункции

Функция ЗапуститьИПодождатьБезВывода(СтрокаЗапуска, ВыводПодавлять = Ложь)
	ЗаписьXML = Новый ЗаписьXML();
	ЗаписьXML.УстановитьСтроку();

	Лог.Информация(СтрокаЗапуска);
	Процесс = СоздатьПроцесс(СтрокаЗапуска, "./", Истина, Истина);
	Процесс.Запустить();
	ПериодОпросаВМиллисекундах = 1000;
	Если ПериодОпросаВМиллисекундах <> 0 Тогда
		Приостановить(ПериодОпросаВМиллисекундах);
	КонецЕсли;
	Пока НЕ Процесс.Завершен ИЛИ Процесс.ПотокВывода.ЕстьДанные ИЛИ Процесс.ПотокОшибок.ЕстьДанные Цикл
		//Сообщить(""+ ТекущаяДата() + " Завершен:"+Строка(Процесс.Завершен) + Строка(Процесс.ПотокВывода.ЕстьДанные) + Строка(Процесс.ПотокОшибок.ЕстьДанные) );
		Если ПериодОпросаВМиллисекундах <> 0 Тогда
			Приостановить(ПериодОпросаВМиллисекундах);
		КонецЕсли;

		ОчереднаяСтрокаВывода = Процесс.ПотокВывода.Прочитать();
		ОчереднаяСтрокаОшибок = Процесс.ПотокОшибок.Прочитать();

		Если Не ПустаяСтрока(ОчереднаяСтрокаВывода) Тогда
			ОчереднаяСтрокаВывода = СтрЗаменить(ОчереднаяСтрокаВывода, Символы.ВК, "");
			Если ОчереднаяСтрокаВывода <> "" Тогда
				//Лог.Информация("%2%1", ОчереднаяСтрокаВывода, Символы.ПС);
				ЗаписьXML.ЗаписатьБезОбработки(ОчереднаяСтрокаВывода);
			КонецЕсли;
		КонецЕсли;

		Если Не ПустаяСтрока(ОчереднаяСтрокаОшибок) Тогда
			Если Найти(ОчереднаяСтрокаОшибок, "No bp log location ") = 0 Тогда 
				ОчереднаяСтрокаОшибок = СтрЗаменить(ОчереднаяСтрокаОшибок, Символы.ВК, "");
				Если ОчереднаяСтрокаОшибок <> "" Тогда
					//Сообщить(ОчереднаяСтрокаОшибок);
					Лог.Информация("%2%1", ОчереднаяСтрокаОшибок, Символы.ПС);
					ЗаписьXML.ЗаписатьБезОбработки(ОчереднаяСтрокаОшибок);
				КонецЕсли;
			КонецЕсли;
		КонецЕсли;

	КонецЦикла;

	ОчереднаяСтрока = СтрЗаменить(Процесс.ПотокВывода.Прочитать(), Символы.ВК, "");
	//Лог.Отладка("%2%1", ОчереднаяСтрока, Символы.ПС);
	ЗаписьXML.ЗаписатьБезОбработки(ОчереднаяСтрока);
	РезультатРаботыПроцесса = ЗаписьXML.Закрыть();

	Возврат Новый Структура("КодВозврата, Результат", Процесс.КодВозврата, РезультатРаботыПроцесса);

КонецФункции // ЗапуститьИПодождатьБезВывода(СтрокаЗапуска)


Функция ЗапуститьИПодождать(СтрокаЗапуска)
	ЗаписьXML = Новый ЗаписьXML();
	ЗаписьXML.УстановитьСтроку();

	Лог.Информация(СтрокаЗапуска);
	Процесс = СоздатьПроцесс(СтрокаЗапуска, "./", Истина, Истина);
	Попытка
		Процесс.Запустить();
	Исключение
		Если ЭтоWindows Тогда
			ШаблонЗапуска = "cmd /c %1";
		Иначе
			ШаблонЗапуска = "sh -c '%1'";
		КонецЕсли;
		Процесс = СоздатьПроцесс(СтрШаблон(ШаблонЗапуска, СтрокаЗапуска), "./", Истина, Истина);
		Процесс.Запустить();
	КонецПопытки;

	ПериодОпросаВМиллисекундах = 1000;
	Если ПериодОпросаВМиллисекундах <> 0 Тогда
		Приостановить(ПериодОпросаВМиллисекундах);
	КонецЕсли;
	Пока НЕ Процесс.Завершен ИЛИ Процесс.ПотокВывода.ЕстьДанные ИЛИ Процесс.ПотокОшибок.ЕстьДанные Цикл
		//Сообщить(""+ ТекущаяДата() + " Завершен:"+Строка(Процесс.Завершен) + Строка(Процесс.ПотокВывода.ЕстьДанные) + Строка(Процесс.ПотокОшибок.ЕстьДанные) );
		Если ПериодОпросаВМиллисекундах <> 0 Тогда
			Приостановить(ПериодОпросаВМиллисекундах);
		КонецЕсли;

		ОчереднаяСтрокаВывода = Процесс.ПотокВывода.Прочитать();
		ОчереднаяСтрокаОшибок = Процесс.ПотокОшибок.Прочитать();

		Если Не ПустаяСтрока(ОчереднаяСтрокаВывода) Тогда
			ОчереднаяСтрокаВывода = СтрЗаменить(ОчереднаяСтрокаВывода, Символы.ВК, "");
			Если ОчереднаяСтрокаВывода <> "" Тогда
				Лог.Информация("%2%1", ОчереднаяСтрокаВывода, Символы.ПС);
				ЗаписьXML.ЗаписатьБезОбработки(ОчереднаяСтрокаВывода);
			КонецЕсли;
		КонецЕсли;

		Если Не ПустаяСтрока(ОчереднаяСтрокаОшибок) Тогда
			Если Найти(ОчереднаяСтрокаОшибок, "No bp log location ") = 0 Тогда 
				ОчереднаяСтрокаОшибок = СтрЗаменить(ОчереднаяСтрокаОшибок, Символы.ВК, "");
				Если ОчереднаяСтрокаОшибок <> "" Тогда
					//Сообщить(ОчереднаяСтрокаОшибок);
					Лог.Информация("%2%1", ОчереднаяСтрокаОшибок, Символы.ПС);
					ЗаписьXML.ЗаписатьБезОбработки(ОчереднаяСтрокаОшибок);
				КонецЕсли;
			КонецЕсли;
		КонецЕсли;

	КонецЦикла;

	ОчереднаяСтрока = СтрЗаменить(Процесс.ПотокВывода.Прочитать(), Символы.ВК, "");
	Лог.Отладка("%2%1", ОчереднаяСтрока, Символы.ПС);
	ЗаписьXML.ЗаписатьБезОбработки(ОчереднаяСтрока);
	РезультатРаботыПроцесса = ЗаписьXML.Закрыть();

	Возврат Новый Структура("КодВозврата, Результат", Процесс.КодВозврата, РезультатРаботыПроцесса);

КонецФункции // ЗапуститьИПодождать(СтрокаЗапуска)

Функция Форматировать(Знач Уровень, Знач Сообщение) Экспорт

	Возврат СтрШаблон("%1: %2 - %3", ТекущаяДата(), УровниЛога.НаименованиеУровня(Уровень), Сообщение);

КонецФункции

ИнициализацияОкружения();