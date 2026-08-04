#!/usr/bin/env swift
import Foundation

private let locales = ["zh-Hans", "zh-Hant", "ja", "ko", "es", "fr", "de", "pt-BR", "it", "ar"]

private struct Entry {
    let key: String
    let values: [String]

    init(_ key: String, _ values: String...) {
        precondition(values.count == locales.count, "\(key) must have \(locales.count) translations")
        self.key = key
        self.values = values
    }
}

private let appEntries: [Entry] = [
    Entry(
        "%@ before", "提前%@", "提前%@", "%@前", "%@ 전", "%@ antes", "%@ avant", "%@ vorher", "%@ antes",
        "%@ prima", "قبل %@"),
    Entry(
        "1 Day Before", "提前 1 天", "提前 1 天", "1日前", "1일 전", "1 día antes", "1 jour avant", "1 Tag vorher",
        "1 dia antes", "1 giorno prima", "قبل يوم واحد"),
    Entry(
        "1 Hour Before", "提前 1 小时", "提前 1 小時", "1時間前", "1시간 전", "1 hora antes", "1 heure avant",
        "1 Stunde vorher", "1 hora antes", "1 ora prima", "قبل ساعة واحدة"),
    Entry(
        "1 Week Before", "提前 1 周", "提前 1 週", "1週間前", "1주 전", "1 semana antes", "1 semaine avant",
        "1 Woche vorher", "1 semana antes", "1 settimana prima", "قبل أسبوع واحد"),
    Entry("About", "关于", "關於", "情報", "정보", "Acerca de", "À propos", "Über", "Sobre", "Informazioni", "حول"),
    Entry(
        "Add Category", "添加分类", "新增分類", "カテゴリを追加", "카테고리 추가", "Añadir categoría", "Ajouter une catégorie",
        "Kategorie hinzufügen", "Adicionar categoria", "Aggiungi categoria", "إضافة فئة"),
    Entry(
        "Add Important Day", "添加重要日", "新增重要日", "大切な日を追加", "소중한 날 추가", "Añadir fecha importante",
        "Ajouter une date importante", "Wichtigen Tag hinzufügen", "Adicionar data importante",
        "Aggiungi giorno importante", "إضافة يوم مهم"),
    Entry(
        "Add Reminder", "添加提醒", "新增提醒", "リマインダーを追加", "미리 알림 추가", "Añadir recordatorio", "Ajouter un rappel",
        "Erinnerung hinzufügen", "Adicionar lembrete", "Aggiungi promemoria", "إضافة تذكير"),
    Entry(
        "Add Tag", "添加标签", "新增標籤", "タグを追加", "태그 추가", "Añadir etiqueta", "Ajouter une étiquette",
        "Tag hinzufügen", "Adicionar etiqueta", "Aggiungi tag", "إضافة وسم"),
    Entry(
        "All Categories", "全部分类", "所有分類", "すべてのカテゴリ", "모든 카테고리", "Todas las categorías",
        "Toutes les catégories", "Alle Kategorien", "Todas as categorias", "Tutte le categorie", "كل الفئات"),
    Entry(
        "All Day", "全天", "全天", "終日", "하루 종일", "Todo el día", "Toute la journée", "Ganztägig", "Dia inteiro",
        "Tutto il giorno", "طوال اليوم"),
    Entry(
        "At Event Time", "事件发生时", "事件發生時", "予定時刻", "이벤트 시간", "A la hora del evento",
        "À l’heure de l’événement", "Zum Ereigniszeitpunkt", "No horário do evento", "All’ora dell’evento",
        "في وقت الحدث"),
    Entry(
        "Automatic Sync", "自动同步", "自動同步", "自動同期", "자동 동기화", "Sincronización automática",
        "Synchronisation automatique", "Automatische Synchronisierung", "Sincronização automática",
        "Sincronizzazione automatica", "مزامنة تلقائية"),
    Entry(
        "Basics", "基本信息", "基本資料", "基本情報", "기본 정보", "Información básica", "Informations de base", "Grundlagen",
        "Informações básicas", "Informazioni di base", "المعلومات الأساسية"),
    Entry(
        "Birthday", "生日", "生日", "誕生日", "생일", "Cumpleaños", "Anniversaire", "Geburtstag", "Aniversário",
        "Compleanno", "عيد ميلاد"),
    Entry(
        "Calendar", "日历", "行事曆", "カレンダー", "캘린더", "Calendario", "Calendrier", "Kalender", "Calendário",
        "Calendario", "التقويم"),
    Entry(
        "Calendar access is not available", "没有日历访问权限", "無法使用行事曆權限", "カレンダーへのアクセス権がありません",
        "캘린더 접근 권한을 사용할 수 없습니다", "El acceso al calendario no está disponible",
        "L’accès au calendrier n’est pas disponible", "Kalenderzugriff ist nicht verfügbar",
        "O acesso ao calendário não está disponível", "L’accesso al calendario non è disponibile",
        "الوصول إلى التقويم غير متاح"),
    Entry(
        "Calendar access is requested when you export", "导出时会申请日历权限", "匯出時會要求行事曆權限", "書き出し時にカレンダーへのアクセスを求めます",
        "내보낼 때 캘린더 접근 권한을 요청합니다", "El acceso al calendario se solicita al exportar",
        "L’accès au calendrier est demandé lors de l’exportation",
        "Kalenderzugriff wird beim Export angefragt", "O acesso ao calendário é solicitado ao exportar",
        "L’accesso al calendario viene richiesto durante l’esportazione",
        "يُطلب الوصول إلى التقويم عند التصدير"),
    Entry(
        "Calendar did not return an event identifier", "系统日历没有返回事件标识", "系統行事曆未傳回事件識別碼",
        "カレンダーから予定IDが返されませんでした", "캘린더가 이벤트 식별자를 반환하지 않았습니다",
        "El calendario no devolvió un identificador de evento",
        "Le calendrier n’a pas renvoyé d’identifiant d’événement",
        "Der Kalender hat keine Ereignis-ID zurückgegeben",
        "O calendário não retornou um identificador de evento",
        "Il calendario non ha restituito un identificatore evento", "لم يُرجع التقويم معرّفًا للحدث"),
    Entry(
        "Cancel", "取消", "取消", "キャンセル", "취소", "Cancelar", "Annuler", "Abbrechen", "Cancelar", "Annulla",
        "إلغاء"),
    Entry(
        "Categories", "已有分类", "現有分類", "カテゴリ", "카테고리", "Categorías", "Catégories", "Kategorien", "Categorias",
        "Categorie", "الفئات"),
    Entry(
        "Category", "分类", "分類", "カテゴリ", "카테고리", "Categoría", "Catégorie", "Kategorie", "Categoria",
        "Categoria", "الفئة"),
    Entry(
        "Category & Tags", "分类与标签", "分類與標籤", "カテゴリとタグ", "카테고리 및 태그", "Categoría y etiquetas",
        "Catégorie et étiquettes", "Kategorie & Tags", "Categoria e etiquetas", "Categoria e tag",
        "الفئة والوسوم"),
    Entry(
        "Category (single selection)", "分类（单选）", "分類（單選）", "カテゴリ（1つ選択）", "카테고리(하나 선택)",
        "Categoría (selección única)", "Catégorie (sélection unique)", "Kategorie (Einzelauswahl)",
        "Categoria (seleção única)", "Categoria (selezione singola)", "الفئة (اختيار واحد)"),
    Entry(
        "Category Name", "分类名称", "分類名稱", "カテゴリ名", "카테고리 이름", "Nombre de la categoría", "Nom de la catégorie",
        "Kategoriename", "Nome da categoria", "Nome categoria", "اسم الفئة"),
    Entry(
        "Chinese Lunar", "农历", "農曆", "中国暦", "음력", "Calendario lunar chino", "Calendrier lunaire chinois",
        "Chinesischer Mondkalender", "Calendário lunar chinês", "Calendario lunare cinese",
        "التقويم القمري الصيني"),
    Entry(
        "Coming up", "即将到来", "即將到來", "もうすぐです", "곧 다가옵니다", "Próximamente", "À venir", "Demnächst", "Em breve",
        "In arrivo", "قريبًا"),
    Entry(
        "Count Style", "计时方式", "計時方式", "カウント方式", "계산 방식", "Estilo de conteo", "Mode de comptage", "Zählweise",
        "Estilo de contagem", "Stile di conteggio", "نمط العد"),
    Entry(
        "Count Up", "正计时", "正計時", "経過日数", "지난 날짜", "Cuenta ascendente", "Compte progressif",
        "Aufwärts zählen", "Contagem crescente", "Conteggio crescente", "عد تصاعدي"),
    Entry(
        "Countdown", "倒计时", "倒數計時", "カウントダウン", "카운트다운", "Cuenta atrás", "Compte à rebours", "Countdown",
        "Contagem regressiva", "Conto alla rovescia", "عد تنازلي"),
    Entry(
        "Created with Taisetsu", "来自 Taisetsu", "由 Taisetsu 建立", "Taisetsuで作成", "Taisetsu에서 생성",
        "Creado con Taisetsu", "Créé avec Taisetsu", "Mit Taisetsu erstellt", "Criado com Taisetsu",
        "Creato con Taisetsu", "أُنشئ باستخدام Taisetsu"),
    Entry("Date", "日期", "日期", "日付", "날짜", "Fecha", "Date", "Datum", "Data", "Data", "التاريخ"),
    Entry(
        "Date Rule", "日期规则", "日期規則", "日付ルール", "날짜 규칙", "Regla de fecha", "Règle de date", "Datumsregel",
        "Regra de data", "Regola della data", "قاعدة التاريخ"),
    Entry("Day", "天", "天", "日", "일", "Día", "Jour", "Tag", "Dia", "Giorno", "يوم"),
    Entry("Days", "天", "天", "日", "일", "Días", "Jours", "Tage", "Dias", "Giorni", "أيام"),
    Entry("Delete", "删除", "刪除", "削除", "삭제", "Eliminar", "Supprimer", "Löschen", "Excluir", "Elimina", "حذف"),
    Entry(
        "Display", "显示", "顯示", "表示", "표시", "Visualización", "Affichage", "Anzeige", "Exibição",
        "Visualizzazione", "العرض"),
    Entry(
        "Does not repeat", "不重复", "不重複", "繰り返さない", "반복 안 함", "No se repite", "Ne se répète pas",
        "Wiederholt sich nicht", "Não se repete", "Non si ripete", "لا يتكرر"),
    Entry("Done", "完成", "完成", "完了", "완료", "Listo", "Terminé", "Fertig", "Concluído", "Fine", "تم"),
    Entry("Edit", "编辑", "編輯", "編集", "편집", "Editar", "Modifier", "Bearbeiten", "Editar", "Modifica", "تعديل"),
    Entry(
        "Edit Important Day", "编辑重要日", "編輯重要日", "大切な日を編集", "소중한 날 편집", "Editar fecha importante",
        "Modifier la date importante", "Wichtigen Tag bearbeiten", "Editar data importante",
        "Modifica giorno importante", "تعديل اليوم المهم"),
    Entry(
        "Enter a name", "请输入名称", "請輸入名稱", "名前を入力してください", "이름을 입력하세요", "Introduce un nombre",
        "Saisissez un nom", "Namen eingeben", "Digite um nome", "Inserisci un nome", "أدخل اسمًا"),
    Entry("Every", "每", "每", "間隔", "매", "Cada", "Tous les", "Alle", "A cada", "Ogni", "كل"),
    Entry(
        "Every %@", "每%@", "每%@", "%@ごと", "%@마다", "Cada %@", "Tous les %@", "Alle %@", "A cada %@", "Ogni %@",
        "كل %@"),
    Entry(
        "Export Next Date to Calendar", "将下一次日期导出到日历", "將下一次日期匯出至行事曆", "次の日付をカレンダーに書き出す", "다음 날짜를 캘린더로 내보내기",
        "Exportar la próxima fecha al calendario", "Exporter la prochaine date vers le calendrier",
        "Nächstes Datum in Kalender exportieren", "Exportar próxima data para o calendário",
        "Esporta la prossima data nel calendario", "تصدير التاريخ التالي إلى التقويم"),
    Entry(
        "Exported. Exporting again will update the same event.", "已导出；再次导出会更新同一事件。", "已匯出；再次匯出會更新同一事件。",
        "書き出しました。再度書き出すと同じ予定が更新されます。", "내보냈습니다. 다시 내보내면 같은 이벤트가 업데이트됩니다.",
        "Exportado. Si vuelves a exportar, se actualizará el mismo evento.",
        "Exporté. Une nouvelle exportation mettra à jour le même événement.",
        "Exportiert. Ein erneuter Export aktualisiert dasselbe Ereignis.",
        "Exportado. Exportar novamente atualizará o mesmo evento.",
        "Esportato. Una nuova esportazione aggiornerà lo stesso evento.",
        "تم التصدير. سيؤدي التصدير مرة أخرى إلى تحديث الحدث نفسه."),
    Entry(
        "Family", "家庭", "家庭", "家族", "가족", "Familia", "Famille", "Familie", "Família", "Famiglia", "العائلة"),
    Entry("Filter", "筛选", "篩選", "絞り込み", "필터", "Filtrar", "Filtrer", "Filtern", "Filtrar", "Filtra", "تصفية"),
    Entry(
        "Gregorian", "公历", "國曆", "グレゴリオ暦", "양력", "Gregoriano", "Grégorien", "Gregorianisch", "Gregoriano",
        "Gregoriano", "الميلادي"),
    Entry("Health", "健康", "健康", "健康", "건강", "Salud", "Santé", "Gesundheit", "Saúde", "Salute", "الصحة"),
    Entry(
        "Hidden", "隐藏", "隱藏", "非表示", "숨김", "Oculto", "Masqué", "Ausgeblendet", "Oculto", "Nascosto", "مخفي"),
    Entry("Home", "首页", "首頁", "ホーム", "홈", "Inicio", "Accueil", "Start", "Início", "Home", "الرئيسية"),
    Entry(
        "Hour: %lld", "时：%lld", "時：%lld", "時：%lld", "시: %lld", "Hora: %lld", "Heure : %lld", "Stunde: %lld",
        "Hora: %lld", "Ora: %lld", "الساعة: %lld"),
    Entry(
        "Important Day Details", "重要日详情", "重要日詳情", "大切な日の詳細", "소중한 날 세부 정보",
        "Detalles de la fecha importante", "Détails de la date importante", "Details zum wichtigen Tag",
        "Detalhes da data importante", "Dettagli del giorno importante", "تفاصيل اليوم المهم"),
    Entry(
        "Important Days This Month", "本月重要日", "本月重要日", "今月の大切な日", "이번 달의 소중한 날",
        "Fechas importantes de este mes", "Dates importantes ce mois-ci", "Wichtige Tage in diesem Monat",
        "Datas importantes deste mês", "Giorni importanti di questo mese", "الأيام المهمة هذا الشهر"),
    Entry(
        "Keep birthdays, anniversaries, and every day worth looking forward to close.",
        "记录生日、纪念日，以及每一个值得期待的日子。", "記錄生日、紀念日，以及每一個值得期待的日子。", "誕生日や記念日、楽しみにしている大切な日をそばに。",
        "생일과 기념일, 기다려지는 모든 날을 가까이 간직하세요.",
        "Guarda cerca los cumpleaños, aniversarios y cada fecha que esperas con ilusión.",
        "Gardez près de vous les anniversaires et toutes les dates que vous attendez.",
        "Behalte Geburtstage, Jahrestage und alle Tage, auf die du dich freust, im Blick.",
        "Mantenha por perto aniversários e todas as datas que você espera com carinho.",
        "Tieni vicini compleanni, anniversari e ogni giorno che aspetti con gioia.",
        "احتفظ بأعياد الميلاد والذكريات وكل يوم تتطلع إليه قريبًا منك."),
    Entry(
        "Leap Month", "闰月", "閏月", "閏月", "윤달", "Mes bisiesto", "Mois intercalaire", "Schaltmonat",
        "Mês intercalar", "Mese intercalare", "شهر كبيس"),
    Entry(
        "Leap lunar month %lld, day %lld", "农历闰%lld月%lld日", "農曆閏%lld月%lld日", "旧暦閏%lld月%lld日",
        "음력 윤%lld월 %lld일", "Mes lunar intercalar %lld, día %lld", "Mois lunaire intercalaire %lld, jour %lld",
        "Schaltmondmonat %lld, Tag %lld", "Mês lunar intercalar %lld, dia %lld",
        "Mese lunare intercalare %lld, giorno %lld", "الشهر القمري الكبيس %lld، اليوم %lld"),
    Entry(
        "Loading important days…", "正在读取重要日…", "正在載入重要日…", "大切な日を読み込み中…", "소중한 날을 불러오는 중…",
        "Cargando fechas importantes…", "Chargement des dates importantes…", "Wichtige Tage werden geladen…",
        "Carregando datas importantes…", "Caricamento dei giorni importanti…", "جارٍ تحميل الأيام المهمة…"),
    Entry("Love", "爱情", "愛情", "恋愛", "사랑", "Amor", "Amour", "Liebe", "Amor", "Amore", "الحب"),
    Entry(
        "Lunar month %lld, day %lld", "农历%lld月%lld日", "農曆%lld月%lld日", "旧暦%lld月%lld日",
        "음력 %lld월 %lld일", "Mes lunar %lld, día %lld", "Mois lunaire %lld, jour %lld",
        "Mondmonat %lld, Tag %lld", "Mês lunar %lld, dia %lld", "Mese lunare %lld, giorno %lld",
        "الشهر القمري %lld، اليوم %lld"),
    Entry(
        "Lunar month intervals count leap months and may land in a different numbered month.",
        "农历月间隔会计入闰月，因此未来可能落在不同编号的月份。",
        "農曆月間隔會計入閏月，因此未來可能落在不同編號的月份。",
        "旧暦の月間隔には閏月も含まれるため、将来は異なる月番号になることがあります。",
        "음력 월 간격에는 윤달도 포함되므로 이후에는 다른 월 번호에 해당할 수 있습니다.",
        "Los intervalos de meses lunares cuentan los meses intercalares y pueden caer en un mes con otro número.",
        "Les intervalles en mois lunaires comptent les mois intercalaires et peuvent tomber sur un autre numéro de mois.",
        "Mondmonat-Intervalle zählen Schaltmonate mit und können künftig in einem anders nummerierten Monat liegen.",
        "Intervalos em meses lunares contam meses intercalares e podem cair em um mês de número diferente.",
        "Gli intervalli in mesi lunari includono i mesi intercalari e possono cadere in un mese con numero diverso.",
        "تحتسب فواصل الأشهر القمرية الأشهر الكبيسة، وقد تقع لاحقًا في شهر ذي رقم مختلف."),
    Entry(
        "Manage Categories", "分类管理", "管理分類", "カテゴリ管理", "카테고리 관리", "Gestionar categorías",
        "Gérer les catégories", "Kategorien verwalten", "Gerenciar categorias", "Gestisci categorie",
        "إدارة الفئات"),
    Entry(
        "Manage Tags", "标签管理", "管理標籤", "タグ管理", "태그 관리", "Gestionar etiquetas", "Gérer les étiquettes",
        "Tags verwalten", "Gerenciar etiquetas", "Gestisci tag", "إدارة الوسوم"),
    Entry(
        "Minute: %lld", "分：%lld", "分：%lld", "分：%lld", "분: %lld", "Minuto: %lld", "Minute : %lld",
        "Minute: %lld", "Minuto: %lld", "Minuto: %lld", "الدقيقة: %lld"),
    Entry("Month", "月", "月", "か月", "개월", "Mes", "Mois", "Monat", "Mês", "Mese", "شهر"),
    Entry("Months", "月", "月", "か月", "개월", "Meses", "Mois", "Monate", "Meses", "Mesi", "أشهر"),
    Entry("Name", "名称", "名稱", "名前", "이름", "Nombre", "Nom", "Name", "Nome", "Nome", "الاسم"),
    Entry(
        "Nearest Important Day", "最近重要日", "最近重要日", "いちばん近い大切な日", "가장 가까운 소중한 날",
        "Fecha importante más próxima", "Date importante la plus proche", "Nächster wichtiger Tag",
        "Data importante mais próxima", "Giorno importante più vicino", "أقرب يوم مهم"),
    Entry(
        "New Category", "新分类", "新分類", "新しいカテゴリ", "새 카테고리", "Nueva categoría", "Nouvelle catégorie",
        "Neue Kategorie", "Nova categoria", "Nuova categoria", "فئة جديدة"),
    Entry(
        "New Important Day", "新建重要日", "新增重要日", "新しい大切な日", "새로운 소중한 날", "Nueva fecha importante",
        "Nouvelle date importante", "Neuer wichtiger Tag", "Nova data importante", "Nuovo giorno importante",
        "يوم مهم جديد"),
    Entry(
        "New Tag", "新标签", "新標籤", "新しいタグ", "새 태그", "Nueva etiqueta", "Nouvelle étiquette", "Neuer Tag",
        "Nova etiqueta", "Nuovo tag", "وسم جديد"),
    Entry(
        "Next Month", "下个月", "下個月", "次の月", "다음 달", "Mes siguiente", "Mois suivant", "Nächster Monat",
        "Próximo mês", "Mese successivo", "الشهر التالي"),
    Entry(
        "Next Occurrence", "下一次发生", "下一次發生", "次回", "다음 발생", "Próxima fecha", "Prochaine occurrence",
        "Nächster Termin", "Próxima ocorrência", "Prossima ricorrenza", "التكرار التالي"),
    Entry("No", "否", "否", "いいえ", "아니요", "No", "Non", "Nein", "Não", "No", "لا"),
    Entry(
        "No Category", "无分类", "無分類", "カテゴリなし", "카테고리 없음", "Sin categoría", "Sans catégorie",
        "Keine Kategorie", "Sem categoria", "Nessuna categoria", "بلا فئة"),
    Entry(
        "No important days this month", "这个月还没有重要日", "本月尚無重要日", "今月は大切な日がありません", "이번 달에는 소중한 날이 없습니다",
        "No hay fechas importantes este mes", "Aucune date importante ce mois-ci",
        "Keine wichtigen Tage in diesem Monat", "Nenhuma data importante neste mês",
        "Nessun giorno importante questo mese", "لا توجد أيام مهمة هذا الشهر"),
    Entry(
        "No important days yet", "还没有重要日", "尚無重要日", "大切な日はまだありません", "아직 소중한 날이 없습니다",
        "Aún no hay fechas importantes", "Aucune date importante pour le moment", "Noch keine wichtigen Tage",
        "Ainda não há datas importantes", "Nessun giorno importante", "لا توجد أيام مهمة بعد"),
    Entry("Notes", "备注", "備註", "メモ", "메모", "Notas", "Notes", "Notizen", "Notas", "Note", "ملاحظات"),
    Entry(
        "Notification access is requested when you add a reminder", "首次添加提醒时会申请通知权限", "首次新增提醒時會要求通知權限",
        "リマインダー追加時に通知へのアクセスを求めます", "미리 알림을 추가할 때 알림 권한을 요청합니다",
        "El acceso a las notificaciones se solicita al añadir un recordatorio",
        "L’accès aux notifications est demandé lors de l’ajout d’un rappel",
        "Benachrichtigungszugriff wird beim Hinzufügen einer Erinnerung angefragt",
        "O acesso às notificações é solicitado ao adicionar um lembrete",
        "L’accesso alle notifiche viene richiesto quando aggiungi un promemoria",
        "يُطلب الوصول إلى الإشعارات عند إضافة تذكير"),
    Entry(
        "Ongoing", "正在进行", "進行中", "進行中", "진행 중", "En curso", "En cours", "Laufend", "Em andamento",
        "In corso", "جارٍ"),
    Entry(
        "Organization", "整理", "整理", "整理", "정리", "Organización", "Organisation", "Organisation", "Organização",
        "Organizzazione", "التنظيم"),
    Entry(
        "Original Date", "原始日期", "原始日期", "元の日付", "원래 날짜", "Fecha original", "Date d’origine",
        "Ursprüngliches Datum", "Data original", "Data originale", "التاريخ الأصلي"),
    Entry(
        "Past", "已经结束", "已結束", "過去", "지난 날", "Pasadas", "Passées", "Vergangen", "Passadas", "Passati",
        "الماضية"),
    Entry("Pin", "置顶", "置頂", "固定", "고정", "Fijar", "Épingler", "Anheften", "Fixar", "Fissa", "تثبيت"),
    Entry(
        "Pinned", "已置顶", "已置頂", "固定済み", "고정됨", "Fijadas", "Épinglées", "Angeheftet", "Fixadas", "Fissati",
        "مثبتة"),
    Entry(
        "Previous Month", "上个月", "上個月", "前の月", "이전 달", "Mes anterior", "Mois précédent", "Vorheriger Monat",
        "Mês anterior", "Mese precedente", "الشهر السابق"),
    Entry(
        "Reminders", "提醒", "提醒", "リマインダー", "미리 알림", "Recordatorios", "Rappels", "Erinnerungen", "Lembretes",
        "Promemoria", "التذكيرات"),
    Entry(
        "Repeat", "重复", "重複", "繰り返す", "반복", "Repetir", "Répéter", "Wiederholen", "Repetir", "Ripeti", "تكرار"),
    Entry(
        "Repeat & Count", "重复与显示", "重複與計時", "繰り返しとカウント", "반복 및 계산", "Repetición y conteo",
        "Répétition et comptage", "Wiederholung & Zählung", "Repetição e contagem", "Ripetizione e conteggio",
        "التكرار والعد"),
    Entry(
        "Repeat Quantity", "重复数量", "重複數量", "繰り返し間隔", "반복 수량", "Cantidad de repetición",
        "Quantité de répétition", "Wiederholungsanzahl", "Quantidade de repetição", "Quantità di ripetizione",
        "كمية التكرار"),
    Entry(
        "Repeat Unit", "重复单位", "重複單位", "繰り返し単位", "반복 단위", "Unidad de repetición", "Unité de répétition",
        "Wiederholungseinheit", "Unidade de repetição", "Unità di ripetizione", "وحدة التكرار"),
    Entry("Save", "保存", "儲存", "保存", "저장", "Guardar", "Enregistrer", "Sichern", "Salvar", "Salva", "حفظ"),
    Entry(
        "Search names, notes, categories, or tags", "搜索名称、备注、分类或标签", "搜尋名稱、備註、分類或標籤", "名前、メモ、カテゴリ、タグを検索",
        "이름, 메모, 카테고리 또는 태그 검색", "Buscar nombres, notas, categorías o etiquetas",
        "Rechercher des noms, notes, catégories ou étiquettes", "Namen, Notizen, Kategorien oder Tags suchen",
        "Buscar nomes, notas, categorias ou etiquetas", "Cerca nomi, note, categorie o tag",
        "البحث في الأسماء أو الملاحظات أو الفئات أو الوسوم"),
    Entry(
        "Settings", "设置", "設定", "設定", "설정", "Ajustes", "Réglages", "Einstellungen", "Ajustes", "Impostazioni",
        "الإعدادات"),
    Entry(
        "Show Both", "同时显示", "同時顯示", "両方表示", "둘 다 표시", "Mostrar ambos", "Afficher les deux",
        "Beides anzeigen", "Mostrar ambos", "Mostra entrambi", "إظهار كليهما"),
    Entry(
        "Show in Widgets", "在小组件中显示", "顯示於小工具", "ウィジェットに表示", "위젯에 표시", "Mostrar en widgets",
        "Afficher dans les widgets", "In Widgets anzeigen", "Mostrar nos widgets", "Mostra nei widget",
        "إظهار في الأدوات"),
    Entry("Shown", "显示", "顯示", "表示", "표시", "Visible", "Affiché", "Angezeigt", "Exibido", "Mostrato", "ظاهر"),
    Entry(
        "Sync & Permissions", "同步与权限", "同步與權限", "同期とアクセス権", "동기화 및 권한", "Sincronización y permisos",
        "Synchronisation et autorisations", "Synchronisierung & Berechtigungen", "Sincronização e permissões",
        "Sincronizzazione e permessi", "المزامنة والأذونات"),
    Entry(
        "System Calendar", "系统日历", "系統行事曆", "システムカレンダー", "시스템 캘린더", "Calendario del sistema",
        "Calendrier système", "Systemkalender", "Calendário do sistema", "Calendario di sistema",
        "تقويم النظام"),
    Entry(
        "Tag Name", "标签名称", "標籤名稱", "タグ名", "태그 이름", "Nombre de la etiqueta", "Nom de l’étiquette", "Tagname",
        "Nome da etiqueta", "Nome tag", "اسم الوسم"),
    Entry("Tags", "标签", "標籤", "タグ", "태그", "Etiquetas", "Étiquettes", "Tags", "Etiquetas", "Tag", "الوسوم"),
    Entry(
        "Tags (multiple selection)", "标签（可多选）", "標籤（可多選）", "タグ（複数選択可）", "태그(여러 개 선택)",
        "Etiquetas (selección múltiple)", "Étiquettes (sélection multiple)", "Tags (Mehrfachauswahl)",
        "Etiquetas (seleção múltipla)", "Tag (selezione multipla)", "الوسوم (اختيار متعدد)"),
    Entry(
        "The repeat interval must be greater than zero", "重复间隔必须大于零", "重複間隔必須大於零", "繰り返し間隔は0より大きくしてください",
        "반복 간격은 0보다 커야 합니다", "El intervalo de repetición debe ser mayor que cero",
        "L’intervalle de répétition doit être supérieur à zéro",
        "Das Wiederholungsintervall muss größer als null sein",
        "O intervalo de repetição deve ser maior que zero",
        "L’intervallo di ripetizione deve essere maggiore di zero", "يجب أن يكون فاصل التكرار أكبر من صفر"),
    Entry(
        "This important day has no upcoming date to export", "这个重要日没有可导出的下一次日期", "這個重要日沒有可匯出的下一次日期",
        "この大切な日には書き出せる次の日付がありません", "이 소중한 날에는 내보낼 다음 날짜가 없습니다",
        "Esta fecha importante no tiene una próxima fecha para exportar",
        "Cette date importante n’a pas de prochaine occurrence à exporter",
        "Dieser wichtige Tag hat kein nächstes Datum zum Exportieren",
        "Esta data importante não tem uma próxima data para exportar",
        "Questo giorno importante non ha una prossima data da esportare",
        "لا يوجد لهذا اليوم المهم تاريخ قادم لتصديره"),
    Entry(
        "Try again later", "请稍后重试", "請稍後再試", "しばらくしてからもう一度お試しください", "나중에 다시 시도하세요",
        "Inténtalo de nuevo más tarde", "Réessayez plus tard", "Später erneut versuchen",
        "Tente novamente mais tarde", "Riprova più tardi", "حاول مرة أخرى لاحقًا"),
    Entry(
        "Unable to Load Important Days", "无法读取重要日", "無法載入重要日", "大切な日を読み込めません", "소중한 날을 불러올 수 없습니다",
        "No se pueden cargar las fechas importantes", "Impossible de charger les dates importantes",
        "Wichtige Tage können nicht geladen werden", "Não foi possível carregar as datas importantes",
        "Impossibile caricare i giorni importanti", "تعذر تحميل الأيام المهمة"),
    Entry(
        "Unable to Open Data", "无法打开数据", "無法開啟資料", "データを開けません", "데이터를 열 수 없습니다",
        "No se pueden abrir los datos", "Impossible d’ouvrir les données",
        "Daten können nicht geöffnet werden", "Não foi possível abrir os dados", "Impossibile aprire i dati",
        "تعذر فتح البيانات"),
    Entry("Unit", "单位", "單位", "単位", "단위", "Unidad", "Unité", "Einheit", "Unidade", "Unità", "الوحدة"),
    Entry(
        "Unpin", "取消置顶", "取消置頂", "固定を解除", "고정 해제", "Desfijar", "Désépingler", "Lösen", "Desafixar", "Rimuovi",
        "إلغاء التثبيت"),
    Entry(
        "Upcoming", "即将到来", "即將到來", "予定", "다가오는 날", "Próximas", "À venir", "Bevorstehend", "Próximas",
        "In arrivo", "القادمة"),
    Entry(
        "Version", "版本", "版本", "バージョン", "버전", "Versión", "Version", "Version", "Versão", "Versione", "الإصدار"
    ),
    Entry("Week", "周", "週", "週間", "주", "Semana", "Semaine", "Woche", "Semana", "Settimana", "أسبوع"),
    Entry("Weeks", "周", "週", "週間", "주", "Semanas", "Semaines", "Wochen", "Semanas", "Settimane", "أسابيع"),
    Entry(
        "Widgets", "小组件", "小工具", "ウィジェット", "위젯", "Widgets", "Widgets", "Widgets", "Widgets", "Widget",
        "الأدوات"),
    Entry("Work", "工作", "工作", "仕事", "업무", "Trabajo", "Travail", "Arbeit", "Trabalho", "Lavoro", "العمل"),
    Entry("Year", "年", "年", "年", "년", "Año", "An", "Jahr", "Ano", "Anno", "سنة"),
    Entry("Years", "年", "年", "年", "년", "Años", "Ans", "Jahre", "Anos", "Anni", "سنوات"),
    Entry("Yes", "是", "是", "はい", "예", "Sí", "Oui", "Ja", "Sim", "Sì", "نعم"),
    Entry(
        "Your data stays on your device and in your private iCloud database.", "数据保存在你的设备与私人 iCloud 数据库中。",
        "資料會保留在你的裝置與私人 iCloud 資料庫中。", "データはデバイスと非公開のiCloudデータベースに保存されます。",
        "데이터는 기기와 비공개 iCloud 데이터베이스에 저장됩니다.",
        "Tus datos permanecen en tu dispositivo y en tu base de datos privada de iCloud.",
        "Vos données restent sur votre appareil et dans votre base iCloud privée.",
        "Deine Daten bleiben auf deinem Gerät und in deiner privaten iCloud-Datenbank.",
        "Seus dados ficam no dispositivo e no seu banco de dados privado do iCloud.",
        "I tuoi dati restano sul dispositivo e nel tuo database iCloud privato.",
        "تبقى بياناتك على جهازك وفي قاعدة بيانات iCloud الخاصة بك."),
    Entry(
        "has an important day", "有重要日", "有重要日", "大切な日があります", "소중한 날이 있습니다", "tiene una fecha importante",
        "contient une date importante", "enthält einen wichtigen Tag", "tem uma data importante",
        "contiene un giorno importante", "يتضمن يومًا مهمًا"),
]

private let widgetEntries: [Entry] = [
    Entry(
        "Anniversary", "纪念日", "紀念日", "記念日", "기념일", "Aniversario", "Anniversaire", "Jahrestag",
        "Aniversário", "Anniversario", "ذكرى سنوية"),
    Entry(
        "Birthday", "生日", "生日", "誕生日", "생일", "Cumpleaños", "Anniversaire", "Geburtstag", "Aniversário",
        "Compleanno", "عيد ميلاد"),
    Entry(
        "Nearest Important Days", "最近重要日", "最近重要日", "いちばん近い大切な日", "가장 가까운 소중한 날",
        "Fechas importantes más próximas", "Dates importantes les plus proches", "Nächste wichtige Tage",
        "Datas importantes mais próximas", "Giorni importanti più vicini", "أقرب الأيام المهمة"),
    Entry(
        "No important days yet", "还没有重要日", "尚無重要日", "大切な日はまだありません", "아직 소중한 날이 없습니다",
        "Aún no hay fechas importantes", "Aucune date importante pour le moment", "Noch keine wichtigen Tage",
        "Ainda não há datas importantes", "Nessun giorno importante", "لا توجد أيام مهمة بعد"),
    Entry(
        "Open Taisetsu to add one", "打开 Taisetsu 添加", "開啟 Taisetsu 新增", "Taisetsuを開いて追加",
        "Taisetsu를 열어 추가하세요", "Abre Taisetsu para añadir una", "Ouvrez Taisetsu pour en ajouter une",
        "Taisetsu öffnen und hinzufügen", "Abra o Taisetsu para adicionar",
        "Apri Taisetsu per aggiungerne uno", "افتح Taisetsu لإضافة يوم"),
    Entry(
        "Pinned", "已置顶", "已置頂", "固定済み", "고정됨", "Fijadas", "Épinglées", "Angeheftet", "Fixadas",
        "Fissati", "مثبتة"),
    Entry(
        "Shows pinned and nearest important days automatically.", "自动显示置顶和离现在最近的重要日。", "自動顯示置頂及最近的重要日。",
        "固定した日と直近の大切な日を自動表示します。", "고정된 날과 가장 가까운 소중한 날을 자동으로 표시합니다.",
        "Muestra automáticamente las fechas fijadas y las más próximas.",
        "Affiche automatiquement les dates épinglées et les plus proches.",
        "Zeigt angeheftete und nächste wichtige Tage automatisch an.",
        "Mostra automaticamente datas fixadas e as mais próximas.",
        "Mostra automaticamente i giorni fissati e quelli più vicini.", "يعرض الأيام المثبتة والأقرب تلقائيًا."
    ),
    Entry(
        "Taisetsu — Important Days", "Taisetsu — 重要日", "Taisetsu — 重要日", "Taisetsu — 大切な日",
        "Taisetsu — 소중한 날", "Taisetsu — Fechas importantes", "Taisetsu — Dates importantes",
        "Taisetsu — Wichtige Tage", "Taisetsu — Datas importantes", "Taisetsu — Giorni importanti",
        "Taisetsu — الأيام المهمة"),
    Entry(
        "Trip", "旅行", "旅行", "旅行", "여행", "Viaje", "Voyage", "Reise", "Viagem", "Viaggio", "رحلة"),
]

private let infoPlistEntries: [Entry] = [
    Entry(
        "CFBundleDisplayName", "重要日", "重要日", "Taisetsu", "Taisetsu", "Taisetsu", "Taisetsu",
        "Taisetsu", "Taisetsu", "Taisetsu", "Taisetsu"),
    Entry(
        "NSCalendarsFullAccessUsageDescription",
        "用于将重要日的下一次日期导出到系统日历。",
        "用於將重要日的下一次日期匯出至系統行事曆。",
        "大切な日の次の日付をカレンダーに書き出すために使用します。",
        "소중한 날의 다음 날짜를 시스템 캘린더로 내보내는 데 사용합니다.",
        "Permite exportar la próxima fecha de un día importante al Calendario.",
        "Permet d’exporter la prochaine date importante vers Calendrier.",
        "Ermöglicht den Export des nächsten wichtigen Datums in den Kalender.",
        "Permite exportar a próxima ocorrência de uma data importante para o Calendário.",
        "Consente di esportare la prossima data importante nel Calendario.",
        "يتيح تصدير التاريخ التالي ليوم مهم إلى التقويم."
    )
]

private func catalogData(entries: [Entry]) throws -> Data {
    var strings: [String: Any] = [:]
    for entry in entries {
        var localizations: [String: Any] = [:]
        for (index, locale) in locales.enumerated() {
            localizations[locale] = [
                "stringUnit": [
                    "state": "translated",
                    "value": entry.values[index],
                ]
            ]
        }
        strings[entry.key] = ["localizations": localizations]
    }
    let catalog: [String: Any] = [
        "sourceLanguage": "en",
        "strings": strings,
        "version": "1.0",
    ]
    var data = try JSONSerialization.data(
        withJSONObject: catalog,
        options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    )
    data.append(0x0A)
    return data
}

private let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
private let outputs: [(String, [Entry])] = [
    ("Taisetsu/Resources/Localizable.xcstrings", appEntries),
    ("Taisetsu/Resources/InfoPlist.xcstrings", infoPlistEntries),
    ("TaisetsuWidget/Resources/Localizable.xcstrings", widgetEntries),
]
private let checkOnly = CommandLine.arguments.contains("--check")

for (path, entries) in outputs {
    let url = root.appending(path: path)
    let expected = try catalogData(entries: entries)
    if checkOnly {
        guard let actual = try? Data(contentsOf: url), actual == expected else {
            FileHandle.standardError.write(Data("Generated localization drift: \(path)\n".utf8))
            exit(1)
        }
    } else {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try expected.write(to: url, options: .atomic)
    }
}

print(checkOnly ? "Localization catalogs match the generator." : "Localization catalogs generated.")
