# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Narasihistorian.Repo.insert!(%Narasihistorian.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Narasihistorian.Repo
alias Narasihistorian.Articles.Article
alias Narasihistorian.Categories.Category

rome =
  %Category{
    category_name: "Ancient Rome",
    slug: "ancient-rome"
  }
  |> Repo.insert!()

middle =
  %Category{
    category_name: "Middle Ages",
    slug: "middle-ages"
  }
  |> Repo.insert!()

discovery =
  %Category{
    category_name: "Ages of Discovery",
    slug: "ages-of-discovery"
  }
  |> Repo.insert!()

napoleonic =
  %Category{
    category_name: "Napoleonic War",
    slug: "napoleonic-war"
  }
  |> Repo.insert!()

world =
  %Category{
    category_name: "World War 1/2",
    slug: "world-war-1/2"
  }
  |> Repo.insert!()

cold =
  %Category{
    category_name: "Cold War",
    slug: "cold-war"
  }
  |> Repo.insert!()

%Article{
  article_name: "Ancient Rome",
  content:
    "Periode Roma yang paling dikenal dan sering dikutip oleh ahli sejarah Roma era Republik, karena menjadi dasar bagi pilar peradaban dunia barat",
  image: "/images/ancient-rome.jpg",
  category: rome
}
|> Repo.insert!()

%Article{
  article_name: "Middle Ages",
  content:
    "Periode Eropa setelah keruntuhan Romawi barat, yang dimana peran Gereja Katolik Roma menjadi sangat dominan secara ekonomi maupun politik",
  image: "/images/medieval-age.jpg",
  category: middle
}
|> Repo.insert!()

%Article{
  article_name: "Age of Discovery",
  content:
    "Era dimulainya penjelajahan samudera yang diinisiasi oleh Spanyol untuk mencari dunia baru dengan semangat Gospel, Glory, dan Gold",
  image: "/images/age-of-discovery.jpg",
  category: discovery
}
|> Repo.insert!()

%Article{
  article_name: "Napoleonic War",
  content:
    "Peperangan besar yang melanda benua Eropa setelah revolusi Perancis, ketika naiknya Napoleon Bonaparte menjadi kaisar Perancis berambisi menguasai seluruh daratan Eropa",
  image: "/images/napoleonic-war.jpg",
  category: napoleonic
}
|> Repo.insert!()

%Article{
  article_name: "World War 1/2",
  content:
    "Awal abad ke 20 ditandai dengan situasi peperangan besar yang dampaknya melanda seluruh dunia terutama di Eropa, akibat munculnya persaingan militer antar blok negara-negara besar Eropa",
  image: "/images/world-war-2.jpg",
  category: world
}
|> Repo.insert!()

%Article{
  article_name: "Cold War",
  content:
    "Berakhirnya perang dunia ke 2 tidak membuat persaingan antar blok belum berakhir, karena melahirkan 2 kubu pemenang perang, yaitu blok barat pimpinan Amerika Serikat dan blok timur pimpinan Uni Soviet",
  image: "/images/cold-war.jpg",
  category: cold
}
|> Repo.insert!()

%Article{
  article_name: "Mesopotamian Civilization",
  content:
    "Salah satu peradaban tertua di dunia yang berkembang di antara Sungai Tigris dan Eufrat, dikenal sebagai tempat lahirnya tulisan dan hukum tertulis.",
  image:
    "https://humanoriginproject.com/wp-content/uploads/2018/11/ancient-mesopotamian-civilizations-thumbnail.jpg",
  category: middle
}
|> Repo.insert!()

%Article{
  article_name: "Ancient Egypt",
  content:
    "Peradaban besar di lembah Sungai Nil yang terkenal dengan piramida, hieroglif, dan sistem kepercayaan terhadap kehidupan setelah kematian.",
  image:
    "https://cdn.britannica.com/57/122157-050-21261E20/Side-view-Sphinx-Great-Pyramid-of-Khufu.jpg?w=300",
  category: cold
}
|> Repo.insert!()

%Article{
  article_name: "Indus Valley Civilization",
  content:
    "Peradaban kuno di wilayah Asia Selatan yang memiliki tata kota maju seperti Mohenjo-daro dan Harappa.",
  image:
    "https://cdn.britannica.com/22/196822-050-0E40EBC2/Ruins-city-Harappa-Pakistan-Punjab.jpg?w=300",
  category: cold
}
|> Repo.insert!()

%Article{
  article_name: "Ancient China",
  content:
    "Peradaban besar Asia Timur yang berkembang sepanjang Sungai Kuning, terkenal dengan dinasti, filsafat Konfusianisme, dan inovasi teknologi.",
  image: "https://cdn.mos.cms.futurecdn.net/kBZA9k5TiE3GwrehfFLMv3-650-80.jpg.webp",
  category: discovery
}
|> Repo.insert!()
