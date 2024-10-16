import Component from "@glimmer/component";
import { modifier } from "ember-modifier";
import loadScript from "discourse/lib/load-script";

// args:
// chartConfig - object
export default class Chart extends Component {
  renderChart = modifier((element) => {
    loadScript("/javascripts/Chart.min.js").then(() => {
      this.chart = new window.Chart(
        element.getContext("2d"),
        this.args.chartConfig
      );
    });

    return () => this.chart?.destroy();
  });

  <template>
    <div ...attributes>
      <div class="chart-canvas-container">
        <canvas {{this.renderChart}} class="chart-canvas"></canvas>
      </div>
    </div>
  </template>
}
