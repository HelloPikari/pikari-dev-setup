<?php
/**
 * Plugin Name: [PROJECT_NAME]
 * Plugin URI:  [PROJECT_HOMEPAGE]
 * Description: [PROJECT_DESCRIPTION]
 * Version:     [VERSION]
 * Author:      [AUTHOR_NAME]
 * Author URI:  [PROJECT_HOMEPAGE]
 * License:     GPL-2.0-or-later
 * License URI: https://www.gnu.org/licenses/gpl-2.0.html
 * Text Domain: [PLUGIN_SLUG]
 * Domain Path: /languages
 *
 * @package [PLUGIN_SLUG]
 */

// Exit if accessed directly.
if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

/**
 * Plugin version.
 */
define( '[PLUGIN_CONSTANT]_VERSION', '[VERSION]' );

/**
 * Plugin directory path.
 */
define( '[PLUGIN_CONSTANT]_DIR', plugin_dir_path( __FILE__ ) );

/**
 * Plugin directory URL.
 */
define( '[PLUGIN_CONSTANT]_URL', plugin_dir_url( __FILE__ ) );

/**
 * Initialize the plugin.
 */
function [PLUGIN_FUNCTION_PREFIX]_init() {
    // Load plugin text domain.
    load_plugin_textdomain( '[PLUGIN_SLUG]', false, dirname( plugin_basename( __FILE__ ) ) . '/languages' );

    // Register Gutenberg blocks.
    [PLUGIN_FUNCTION_PREFIX]_register_blocks();

    // Hook into WordPress.
    add_action( 'wp_enqueue_scripts', '[PLUGIN_FUNCTION_PREFIX]_enqueue_scripts' );

    // Add more initialization code here.
}
add_action( 'init', '[PLUGIN_FUNCTION_PREFIX]_init' );

/**
 * Register Gutenberg blocks.
 */
function [PLUGIN_FUNCTION_PREFIX]_register_blocks() {
    $build_dir = __DIR__ . '/build/blocks';

    if ( ! file_exists( $build_dir ) ) {
        return;
    }

    $block_json_files = glob( $build_dir . '/*/block.json' );

    foreach ( $block_json_files as $block_json_file ) {
        register_block_type( dirname( $block_json_file ) );
    }
}

/**
 * Enqueue plugin scripts and styles.
 */
function [PLUGIN_FUNCTION_PREFIX]_enqueue_scripts() {
    // Enqueue your scripts and styles here.
    // Example:
    // wp_enqueue_style( '[PLUGIN_SLUG]', [PLUGIN_CONSTANT]_URL . 'assets/css/style.css', array(), [PLUGIN_CONSTANT]_VERSION );
    // wp_enqueue_script( '[PLUGIN_SLUG]', [PLUGIN_CONSTANT]_URL . 'assets/js/script.js', array( 'jquery' ), [PLUGIN_CONSTANT]_VERSION, true );
}

/**
 * Activation hook.
 */
function [PLUGIN_FUNCTION_PREFIX]_activate() {
    // Code to run on plugin activation.
    flush_rewrite_rules();
}
register_activation_hook( __FILE__, '[PLUGIN_FUNCTION_PREFIX]_activate' );

/**
 * Deactivation hook.
 */
function [PLUGIN_FUNCTION_PREFIX]_deactivate() {
    // Code to run on plugin deactivation.
    flush_rewrite_rules();
}
register_deactivation_hook( __FILE__, '[PLUGIN_FUNCTION_PREFIX]_deactivate' );
