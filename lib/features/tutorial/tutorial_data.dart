/// Content for each onboarding page. Keeping this separate from the screen
/// mirrors the reference tutorial package and makes the page order explicit.
class TutorialPageData {
  const TutorialPageData({
    required this.asset,
    required this.title,
    required this.description,
  });

  final String asset;
  final String title;
  final String description;
}

const tutorialAssets = <String>[
  'assets/lotties/qr.json',
  'assets/lotties/add.json',
  'assets/lotties/edit.json',
  'assets/lotties/share.json',
  'assets/lotties/start.json',
];

const tutorialCopy = <String, List<List<String>>>{
  'es': [
    ['Tus códigos QR, en un solo lugar', 'Crea, lee y guarda códigos QR de forma rápida, clara y privada.'],
    ['Agrega tus QR', 'Crea un código nuevo, elige su tipo y completa la información que quieres compartir.'],
    ['Personalízalos', 'Ajusta colores, formas, ojos, degradados y logo sin perder la legibilidad.'],
    ['Comparte y exporta', 'Guarda tus códigos y compártelos como PNG, JPG o PDF cuando los necesites.'],
    ['Empieza con QRfri', 'Tu biblioteca QR está lista. Crea tu primer código y ten todo bajo control.'],
  ],
  'en': [
    ['Your QR codes, all in one place', 'Create, read, and save QR codes quickly, clearly, and privately.'],
    ['Add your QR codes', 'Create a new code, choose its type, and enter the information you want to share.'],
    ['Customize them', 'Adjust colors, shapes, eyes, gradients, and logo without losing readability.'],
    ['Share and export', 'Save your codes and share them as PNG, JPG, or PDF whenever you need them.'],
    ['Get started with QRfri', 'Your QR library is ready. Create your first code and keep everything under control.'],
  ],
  'pt': [
    ['Seus códigos QR em um só lugar', 'Crie, leia e salve códigos QR de forma rápida, clara e privada.'],
    ['Adicione seus QR', 'Crie um novo código, escolha o tipo e informe o conteúdo que deseja compartilhar.'],
    ['Personalize seus códigos', 'Ajuste cores, formas, olhos, gradientes e logo sem perder a legibilidade.'],
    ['Compartilhe e exporte', 'Salve seus códigos e compartilhe-os como PNG, JPG ou PDF quando precisar.'],
    ['Comece com o QRfri', 'Sua biblioteca QR está pronta. Crie seu primeiro código e mantenha tudo sob controle.'],
  ],
  'fr': [
    ['Vos codes QR au même endroit', 'Créez, lisez et enregistrez vos codes QR rapidement, clairement et en privé.'],
    ['Ajoutez vos codes QR', 'Créez un nouveau code, choisissez son type et saisissez les informations à partager.'],
    ['Personnalisez-les', 'Réglez les couleurs, formes, yeux, dégradés et logo sans perdre en lisibilité.'],
    ['Partagez et exportez', 'Enregistrez vos codes et partagez-les en PNG, JPG ou PDF quand vous en avez besoin.'],
    ['Commencez avec QRfri', 'Votre bibliothèque QR est prête. Créez votre premier code et gardez tout sous contrôle.'],
  ],
  'zh': [
    ['二维码尽在一处', '快速、清晰且私密地创建、读取和保存二维码。'],
    ['添加你的二维码', '创建新二维码，选择类型并填写要分享的信息。'],
    ['个性化二维码', '调整颜色、形状、定位点、渐变和标志，同时保持可读性。'],
    ['分享和导出', '保存二维码，并在需要时以 PNG、JPG 或 PDF 格式分享。'],
    ['开始使用 QRfri', '你的二维码库已准备就绪。创建第一个二维码，轻松管理所有内容。'],
  ],
  'de': [
    ['Deine QR-Codes an einem Ort', 'Erstelle, lies und speichere QR-Codes schnell, übersichtlich und privat.'],
    ['QR-Codes hinzufügen', 'Erstelle einen neuen Code, wähle den Typ und gib die gewünschten Informationen ein.'],
    ['Individuell gestalten', 'Passe Farben, Formen, Augen, Verläufe und Logo an, ohne die Lesbarkeit zu verlieren.'],
    ['Teilen und exportieren', 'Speichere deine Codes und teile sie bei Bedarf als PNG, JPG oder PDF.'],
    ['Mit QRfri starten', 'Deine QR-Bibliothek ist bereit. Erstelle deinen ersten Code und behalte alles im Blick.'],
  ],
  'ja': [
    ['QRコードをひとつの場所で管理', 'QRコードの作成、読み取り、保存をすばやく安全に行えます。'],
    ['QRコードを追加', '新しいコードを作成し、種類を選んで共有する情報を入力します。'],
    ['自分らしくカスタマイズ', '読みやすさを保ちながら、色、形、目、グラデーション、ロゴを調整できます。'],
    ['共有と書き出し', 'コードを保存し、必要なときに PNG、JPG、PDF で共有できます。'],
    ['QRfriを始める', 'QRライブラリの準備ができました。最初のコードを作成して管理を始めましょう。'],
  ],
  'ko': [
    ['QR 코드를 한곳에서 관리하세요', 'QR 코드를 빠르고 명확하게 만들고 읽고 안전하게 저장하세요.'],
    ['QR 코드 추가', '새 코드를 만들고 유형을 선택한 뒤 공유할 정보를 입력하세요.'],
    ['나만의 스타일로 꾸미기', '가독성을 유지하면서 색상, 모양, 눈, 그라데이션과 로고를 조정하세요.'],
    ['공유 및 내보내기', '코드를 저장하고 필요할 때 PNG, JPG 또는 PDF로 공유하세요.'],
    ['QRfri 시작하기', 'QR 라이브러리가 준비되었습니다. 첫 코드를 만들고 모든 것을 관리하세요.'],
  ],
  'it': [
    ['I tuoi codici QR in un unico posto', 'Crea, leggi e salva codici QR in modo rapido, chiaro e privato.'],
    ['Aggiungi i tuoi QR', 'Crea un nuovo codice, scegli il tipo e inserisci le informazioni da condividere.'],
    ['Personalizzali', 'Regola colori, forme, occhi, gradienti e logo mantenendo la leggibilità.'],
    ['Condividi ed esporta', 'Salva i tuoi codici e condividili in PNG, JPG o PDF quando ti servono.'],
    ['Inizia con QRfri', 'La tua libreria QR è pronta. Crea il primo codice e tieni tutto sotto controllo.'],
  ],
  'ru': [
    ['Все QR-коды в одном месте', 'Создавайте, считывайте и сохраняйте QR-коды быстро, понятно и конфиденциально.'],
    ['Добавляйте свои QR-коды', 'Создайте новый код, выберите тип и введите информацию для публикации.'],
    ['Настройте их под себя', 'Меняйте цвета, формы, элементы, градиенты и логотип, сохраняя читаемость.'],
    ['Делитесь и экспортируйте', 'Сохраняйте коды и делитесь ими в формате PNG, JPG или PDF.'],
    ['Начните с QRfri', 'Ваша библиотека QR готова. Создайте первый код и управляйте всем в одном месте.'],
  ],
};

List<TutorialPageData> tutorialPagesFor(String languageCode) {
  final copy = tutorialCopy[languageCode] ?? tutorialCopy['en']!;
  return List<TutorialPageData>.generate(
    tutorialAssets.length,
    (index) => TutorialPageData(
      asset: tutorialAssets[index],
      title: copy[index][0],
      description: copy[index][1],
    ),
  );
}
