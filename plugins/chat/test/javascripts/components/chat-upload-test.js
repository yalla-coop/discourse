import { render, triggerEvent } from "@ember/test-helpers";
import hbs from "htmlbars-inline-precompile";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";

const IMAGE_FIXTURE = {
  id: 290,
  url: null, // Nulled out to avoid actually setting the img src - avoids an HTTP request
  original_filename: "image.jpg",
  filesize: 172214,
  width: 1024,
  height: 768,
  thumbnail_width: 666,
  thumbnail_height: 500,
  extension: "jpeg",
  short_url: "upload://mnCnqY5tunCFw2qMgtPnu1mu1C9.jpeg",
  short_path: "/uploads/short-url/mnCnqY5tunCFw2qMgtPnu1mu1C9.jpeg",
  retain_hours: null,
  human_filesize: "168 KB",
  dominant_color: "788370", // rgb(120, 131, 112)
};

const VIDEO_FIXTURE = {
  id: 290,
  url: null, // Nulled out to avoid actually setting the src - avoids an HTTP request
  original_filename: "video.mp4",
  filesize: 172214,
  width: 1024,
  height: 768,
  thumbnail_width: 666,
  thumbnail_height: 500,
  extension: "mp4",
  short_url: "upload://mnCnqY5tunCFw2qMgtPnu1mu1C9.mp4",
  short_path: "/uploads/short-url/mnCnqY5tunCFw2qMgtPnu1mu1C9.mp4",
  retain_hours: null,
  human_filesize: "168 KB",
};

const AUDIO_FIXTURE = {
  id: 290,
  url: null, // Nulled out to avoid actually setting the src - avoids an HTTP request
  original_filename: "song.mp3",
  filesize: 172214,
  width: 1024,
  height: 768,
  thumbnail_width: 666,
  thumbnail_height: 500,
  extension: "mp3",
  short_url: "upload://mnCnqY5tunCFw2qMgtPnu1mu1C9.mp3",
  short_path: "/uploads/short-url/mnCnqY5tunCFw2qMgtPnu1mu1C9.mp3",
  retain_hours: null,
  human_filesize: "168 KB",
};

const TXT_FIXTURE = {
  id: 290,
  url: "https://example.com/file.txt",
  original_filename: "file.txt",
  filesize: 172214,
  extension: "txt",
  short_url: "upload://mnCnqY5tunCFw2qMgtPnu1mu1C9.jpeg",
  short_path: "/uploads/short-url/mnCnqY5tunCFw2qMgtPnu1mu1C9.jpeg",
  retain_hours: null,
  human_filesize: "168 KB",
};

module("Discourse Chat | Component | chat-upload", function (hooks) {
  setupRenderingTest(hooks);

  test("with an image", async function (assert) {
    this.set("upload", IMAGE_FIXTURE);

    await render(hbs`<ChatUpload @upload={{this.upload}} />`);

    assert.dom("img.chat-img-upload").exists("displays as an image");
    assert
      .dom("img.chat-img-upload")
      .hasProperty("loading", "lazy", "is lazy loading");

    assert
      .dom("img.chat-img-upload")
      .hasStyle(
        { backgroundColor: "rgb(120, 131, 112)" },
        "sets background to dominant color"
      );

    await triggerEvent("img.chat-img-upload", "load"); // Fake that the image has loaded

    assert
      .dom("img.chat-img-upload")
      .doesNotHaveStyle(
        "backgroundColor",
        "removes the background color once the image has loaded"
      );
  });

  test("with a video", async function (assert) {
    this.set("upload", VIDEO_FIXTURE);

    await render(hbs`<ChatUpload @upload={{this.upload}} />`);

    assert.dom("video.chat-video-upload").exists("displays as an video");
    assert.dom("video.chat-video-upload").hasAttribute("controls");
    assert
      .dom("video.chat-video-upload")
      .hasAttribute(
        "preload",
        "metadata",
        "video has correct preload settings"
      );
  });

  test("with a audio", async function (assert) {
    this.set("upload", AUDIO_FIXTURE);

    await render(hbs`<ChatUpload @upload={{this.upload}} />`);

    assert.dom("audio.chat-audio-upload").exists("displays as an audio");
    assert.dom("audio.chat-audio-upload").hasAttribute("controls");
    assert
      .dom("audio.chat-audio-upload")
      .hasAttribute(
        "preload",
        "metadata",
        "audio has correct preload settings"
      );
  });

  test("non image upload", async function (assert) {
    this.set("upload", TXT_FIXTURE);

    await render(hbs`<ChatUpload @upload={{this.upload}} />`);

    assert.dom("a.chat-other-upload").exists("displays as a link");
    assert
      .dom("a.chat-other-upload")
      .hasAttribute("href", TXT_FIXTURE.url, "has the correct URL");
  });
});
