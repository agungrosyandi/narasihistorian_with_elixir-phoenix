alias Narasihistorian.Repo
alias Narasihistorian.Articles.Article
alias Narasihistorian.Categories.Category
alias Narasihistorian.Accounts.User

# ============================================================================
# CATEGORIES
# ============================================================================

categories =
  [
    %{
      category_name: "Ancient Rome",
      slug: "ancient-rome",
      description: "Periode Roma yang paling dikenal dan sering dikutip oleh ahli sejarah",
      image_category: "/images/ancient-rome.jpg"
    },
    %{
      category_name: "Middle Ages",
      slug: "middle-ages",
      description: "Periode Eropa setelah keruntuhan Romawi barat",
      image_category: "/images/medieval-age.jpg"
    },
    %{
      category_name: "Ages of Discovery",
      slug: "ages-of-discovery",
      description: "Era penjelajahan samudera oleh bangsa Eropa",
      image_category: "/images/age-of-discovery.jpg"
    },
    %{
      category_name: "Napoleonic War",
      slug: "napoleonic-war",
      description: "Peperangan besar yang melanda benua Eropa",
      image_category: "/images/napoleonic-war.jpg"
    },
    %{
      category_name: "World War 1/2",
      slug: "world-war-1/2",
      description: "Peperangan besar awal abad ke 20",
      image_category: "/images/world-war-2.jpg"
    },
    %{
      category_name: "Cold War",
      slug: "cold-war",
      description: "Persaingan blok barat dan timur pasca PD2",
      image_category: "/images/cold-war.jpg"
    }
  ]
  |> Enum.map(fn cat ->
    case Repo.get_by(Category, slug: cat.slug) do
      nil ->
        %Category{}
        |> Ecto.Changeset.cast(cat, [:category_name, :slug, :description, :image_category])
        |> Repo.insert!()

      existing ->
        existing
    end
  end)

IO.puts("Categories ready: #{length(categories)}")

# ============================================================================
# USERS
# ============================================================================

users = Repo.all(User)

if users == [] do
  raise "No users found! Please create at least one user first via /register"
end

IO.puts("Users found: #{length(users)}")

# ============================================================================
# ARTICLE TEMPLATES
# ============================================================================

titles = [
  "Sejarah Peradaban",
  "Kejayaan Kekaisaran",
  "Runtuhnya Dinasti",
  "Perang Besar",
  "Revolusi Politik",
  "Penaklukan Wilayah",
  "Kebangkitan Bangsa",
  "Era Keemasan",
  "Konflik Bersejarah",
  "Perjanjian Damai",
  "Ekspedisi Militer",
  "Warisan Budaya",
  "Transformasi Sosial",
  "Krisis Kekuasaan",
  "Legenda Sejarah"
]

contents = [
  "<p>Peristiwa bersejarah ini terjadi pada masa kejayaan kekaisaran besar yang pernah menguasai sebagian besar wilayah dunia. Para pemimpin saat itu mengambil keputusan penting yang mengubah arah peradaban manusia untuk berabad-abad ke depan.</p><p>Dampak dari kejadian ini masih dapat dirasakan hingga saat ini, terutama dalam sistem pemerintahan dan budaya masyarakat modern.</p>",
  "<p>Dalam catatan sejarah, periode ini merupakan salah satu yang paling penuh gejolak. Berbagai kekuatan besar saling bersaing untuk mendominasi wilayah strategis yang kaya sumber daya alam.</p><p>Para sejarawan mencatat bahwa keputusan yang diambil pada masa ini menjadi fondasi bagi tatanan dunia yang kita kenal sekarang.</p>",
  "<p>Kisah ini bermula dari sebuah konflik kecil yang kemudian berkembang menjadi perang besar yang melibatkan hampir seluruh kekuatan dunia pada zamannya. Ribuan tentara gugur dalam pertempuran yang berlangsung selama bertahun-tahun.</p><p>Namun dari kehancuran tersebut, lahirlah sebuah peradaban baru yang lebih maju dan lebih toleran terhadap perbedaan.</p>",
  "<p>Peradaban ini dikenal dengan kemajuan ilmu pengetahuan dan teknologinya yang jauh melampaui zamannya. Para ilmuwan dan filsuf dari era ini memberikan kontribusi besar bagi perkembangan pemikiran manusia.</p><p>Warisan intelektual mereka menjadi dasar bagi revolusi ilmiah yang terjadi beberapa abad kemudian di Eropa.</p>",
  "<p>Revolusi ini dimulai dari ketidakpuasan rakyat terhadap sistem pemerintahan yang korup dan tidak adil. Gerakan rakyat yang awalnya kecil kemudian membesar dan berhasil menggulingkan kekuasaan yang telah berlangsung selama ratusan tahun.</p><p>Perubahan yang terjadi membawa angin segar bagi kehidupan masyarakat, meskipun prosesnya penuh dengan pengorbanan dan penderitaan.</p>"
]

images = [
  "/images/ancient-rome.jpg",
  "/images/medieval-age.jpg",
  "/images/world-war-2.jpg",
  "/images/cold-war.jpg"
]

# ============================================================================
# SEED ARTICLES
# ============================================================================

IO.puts("Seeding 1000 fake articles...")

category_ids = Enum.map(categories, & &1.id)
user_ids = Enum.map(users, & &1.id)

1..1000
|> Enum.each(fn i ->
  title =
    "#{Enum.random(titles)} #{i} - #{Enum.random(["Kuno", "Modern", "Abad Pertengahan", "Kontemporer"])}"

  %Article{}
  |> Article.changeset(%{
    article_name: title,
    content: Enum.random(contents),
    status: Enum.random(["published", "published", "published"]),
    category_id: Enum.random(category_ids),
    image: Enum.random(images)
  })
  |> Ecto.Changeset.put_change(:user_id, Enum.random(user_ids))
  |> Repo.insert!()

  if rem(i, 500) == 0, do: IO.puts("Inserted #{i} articles...")
end)

IO.puts("Done! 30 fake articles inserted.")
