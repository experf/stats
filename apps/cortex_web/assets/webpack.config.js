const path = require('path');
const glob = require('glob');
const HardSourceWebpackPlugin = require('hard-source-webpack-plugin');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const TerserPlugin = require('terser-webpack-plugin');
const OptimizeCSSAssetsPlugin = require('optimize-css-assets-webpack-plugin');
const CopyWebpackPlugin = require('copy-webpack-plugin');

module.exports = (env, options) => {
  const devMode = options.mode !== 'production';

  return {
    optimization: {
      minimizer: [
        new TerserPlugin({ cache: true, parallel: true, sourceMap: devMode }),
        new OptimizeCSSAssetsPlugin({})
      ]
    },
    entry: {
      // DO NOT want this, Bootstrap has a ton of JS lying around in it...
      // 'app': glob.sync('./vendor/**/*.js').concat(['./js/app.js']),
      'app': []
        .concat(glob.sync('./vendor/jsoneditor/src/js/**/*.js'))
        .concat(glob.sync('./vendor/json-schema-tools/dist/**/*.js'))
        .concat(['./js/app.js']),
    },
    output: {
      filename: '[name].js',
      path: path.resolve(__dirname, '../priv/static/js'),
      publicPath: '/js/'
    },
    devtool: devMode ? 'eval-cheap-module-source-map' : undefined,
    module: {
      rules: [
        {
          test: /\.(j|t)s?$/,
          exclude: /node_modules/,
          use: {
            // loader: 'babel-loader'
            loader: 'ts-loader',
          }
        },
        {
          test: /\.[s]?css$/,
          use: [
            MiniCssExtractPlugin.loader,
            'css-loader',
            'sass-loader',
          ],
        },
        // Breaks JSONEditor buttons
        // {
        //   test: /\.(png|jpe?g|gif|svg)$/i,
        //   use: [
        //     {
        //       loader: 'url-loader',
        //       options: {
        //         limit: 8192,
        //       }
        //     },
        //   ],
        // },
        {
          test: /\.(png|jpe?g|gif|svg)$/i,
          use: [
            'file-loader',
          ],
        },
      ]
    },
    resolve: {
      // extensions: [".ts", ".tsx", ".js", ".jsx"],
      extensions: [".ts", ".js"],
      alias: {
        "jsoneditor": path.resolve(__dirname, "vendor", "jsoneditor"),
        "json-schema-tools": path.resolve(__dirname, "vendor", "json-schema-tools"),
        '@': path.resolve(__dirname, 'js'),
      }
    },
    plugins: [
      new MiniCssExtractPlugin({ filename: '../css/[name].css' }),
      new CopyWebpackPlugin([{ from: 'static/', to: '../' }])
    ]
    .concat(devMode ? [new HardSourceWebpackPlugin()] : [])
  }
};
