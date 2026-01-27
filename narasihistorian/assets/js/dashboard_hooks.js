export const DashboardHooks = {
  TrendChart: {
    mounted() {
      const ctx = document.getElementById("trend-canvas").getContext("2d");
      const trendData = JSON.parse(this.el.dataset.trend);

      // trendData is now [["2025-12-28", 0], ["2025-12-29", 1], ...]

      const labels = trendData.map((item) => {
        const date = new Date(item[0]);
        return date.toLocaleDateString("en-US", {
          month: "short",
          day: "numeric",
        });
      });

      const data = trendData.map((item) => item[1]);

      this.chart = new Chart(ctx, {
        type: "line",
        data: {
          labels: labels,
          datasets: [
            {
              label: "Articles Published",
              data: data,
              borderColor: "rgb(254, 223, 22)",
              // backgroundColor: "rgba(59, 130, 246, 0.1)",
              tension: 0.4,
              fill: true,
            },
          ],
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          plugins: {
            legend: {
              display: false,
            },
          },
          scales: {
            y: {
              beginAtZero: true,
              ticks: {
                stepSize: 1,
              },
            },
          },
        },
      });
    },
    updated() {
      const trendData = JSON.parse(this.el.dataset.trend);

      const labels = trendData.map((item) => {
        const date = new Date(item[0]);
        return date.toLocaleDateString("en-US", {
          month: "short",
          day: "numeric",
        });
      });

      const data = trendData.map((item) => item[1]);

      this.chart.data.labels = labels;
      this.chart.data.datasets[0].data = data;
      this.chart.update();
    },
    destroyed() {
      if (this.chart) {
        this.chart.destroy();
      }
    },
  },

  RatioChart: {
    mounted() {
      const ctx = document.getElementById("ratio-canvas").getContext("2d");
      const published = parseInt(this.el.dataset.published);
      const draft = parseInt(this.el.dataset.draft);

      this.chart = new Chart(ctx, {
        type: "doughnut",
        data: {
          labels: ["Published", "Draft"],
          datasets: [
            {
              data: [published, draft],
              backgroundColor: ["rgb(34, 197, 94)", "rgb(234, 179, 8)"],
              borderWidth: 0,
            },
          ],
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          plugins: {
            legend: {
              position: "bottom",
            },
          },
        },
      });
    },
    updated() {
      const published = parseInt(this.el.dataset.published);
      const draft = parseInt(this.el.dataset.draft);

      this.chart.data.datasets[0].data = [published, draft];
      this.chart.update();
    },
    destroyed() {
      if (this.chart) {
        this.chart.destroy();
      }
    },
  },

  FrequencyChart: {
    mounted() {
      const ctx = document.getElementById("frequency-canvas").getContext("2d");
      const frequencyData = JSON.parse(this.el.dataset.frequency);

      // frequencyData is now [{"period": "2025-12-28", "count": 0}, ...]

      const labels = frequencyData.map((item) => {
        const date = new Date(item.period);
        return date.toLocaleDateString("en-US", {
          month: "short",
          day: "numeric",
        });
      });

      const data = frequencyData.map((item) => item.count);

      this.chart = new Chart(ctx, {
        type: "bar",
        data: {
          labels: labels,
          datasets: [
            {
              label: "Articles Published",
              data: data,
              backgroundColor: "rgb(254, 223, 22)",
              // borderColor: "rgb(59, 130, 246)",
              borderWidth: 1,
            },
          ],
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          plugins: {
            legend: {
              display: false,
            },
          },
          scales: {
            y: {
              beginAtZero: true,
              ticks: {
                stepSize: 1,
              },
            },
          },
        },
      });
    },
    updated() {
      const frequencyData = JSON.parse(this.el.dataset.frequency);

      const labels = frequencyData.map((item) => {
        const date = new Date(item.period);
        return date.toLocaleDateString("en-US", {
          month: "short",
          day: "numeric",
        });
      });

      const data = frequencyData.map((item) => item.count);

      this.chart.data.labels = labels;
      this.chart.data.datasets[0].data = data;
      this.chart.update();
    },
    destroyed() {
      if (this.chart) {
        this.chart.destroy();
      }
    },
  },
};
