import { click, render } from "@ember/test-helpers";
import hbs from "htmlbars-inline-precompile";
import { module, skip, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import { queryAll } from "discourse/tests/helpers/qunit-helpers";

const youtubeCooked =
  "<p>written text</p>" +
  '<div class="youtube-onebox lazy-video-container" data-video-id="ytId1" data-video-title="Cats are great" data-provider-name="youtube"> <a href="https://www.youtube.com/watch?v=ytId1"></a>Vid 1</div>' +
  "<p>more written text</p>" +
  '<div class="youtube-onebox lazy-video-container" data-video-id="ytId2" data-video-title="Kittens are great" data-provider-name="youtube"> <a href="https://www.youtube.com/watch?v=ytId2"></a>Vid 2</div>' +
  "<p>and even more</p>";

const animatedImageCooked =
  "<p>written text</p>" +
  '<p><img src="/images/avatar.png" width="8" height="8" class="animated onebox"></img></p>' +
  "<p>more written text</p>" +
  '<p><img src="/images/d-logo-sketch-small.png" width="8" height="8" class="animated onebox"></img></p>' +
  "<p>and even more</p>";

const externalImageCooked =
  "<p>written text</p>" +
  '<p><a href="http://cat1.com" class="onebox"><img src="/images/d-logo-sketch-small.png" width=8" height="8"></img></a></p>' +
  "<p>more written text</p>" +
  '<p><a href="http://cat2.com" class="onebox"><img src="/images/d-logo-sketch-small.png" width=8" height="8"></img></a></p>' +
  "<p>and even more</p>";

const imageCooked =
  "<p>written text</p>" +
  '<p><img src="/images/avatar.png" alt="shows alt" width="8" height="8"></p>' +
  "<p>more written text</p>" +
  '<p><img src="/images/d-logo-sketch-small.png" alt="" width="8" height="8"></p>' +
  "<p>and even more</p>" +
  '<p><img src="/images/d-logo-sketch.png" class="emoji"></p>';

const galleryCooked =
  "<p>written text</p>" +
  '<div class="onebox imgur-album">' +
  '<a href="https://imgur.com/gallery/yyVx5lJ">' +
  '<span class="outer-box"><span><span class="album-title">Le tomtom album</span></span></span>' +
  '<img src="/images/avatar.png" title="Solution" height="315" width="600">' +
  "</a>" +
  "</div>" +
  "<p>more written text</p>";

const evilString = "<script>someeviltitle</script>";
const evilStringEscaped = "&lt;script&gt;someeviltitle&lt;/script&gt;";

module("Discourse Chat | Component | chat message collapser", function (hooks) {
  setupRenderingTest(hooks);

  test("escapes uploads header", async function (assert) {
    this.set("uploads", [{ original_filename: evilString }]);
    await render(hbs`<ChatMessageCollapser @uploads={{this.uploads}} />`);

    assert
      .dom(".chat-message-collapser-link-small")
      .includesHtml(evilStringEscaped);
  });
});

module(
  "Discourse Chat | Component | chat message collapser youtube",
  function (hooks) {
    setupRenderingTest(hooks);

    test("escapes youtube header", async function (assert) {
      this.set(
        "cooked",
        youtubeCooked.replace(
          "https://www.youtube.com/watch?v=ytId1",
          `https://www.youtube.com/watch?v=${evilString}`
        )
      );
      await render(hbs`<ChatMessageCollapser @cooked={{this.cooked}} />`);

      assert
        .dom(".chat-message-collapser-link")
        .hasProperty(
          "href",
          "https://www.youtube.com/watch?v=%3Cscript%3Esomeeviltitle%3C/script%3E"
        );
    });

    test("shows youtube link in header", async function (assert) {
      this.set("cooked", youtubeCooked);

      await render(hbs`<ChatMessageCollapser @cooked={{this.cooked}} />`);

      const link = queryAll(".chat-message-collapser-link");

      assert.strictEqual(link.length, 2, "two youtube links rendered");
      assert
        .dom(link[0])
        .hasAttribute("href", "https://www.youtube.com/watch?v=ytId1");
      assert
        .dom(link[1])
        .hasAttribute("href", "https://www.youtube.com/watch?v=ytId2");
    });

    test("shows all user written text", async function (assert) {
      youtubeCooked.youtubeid;
      this.set("cooked", youtubeCooked);

      await render(hbs`<ChatMessageCollapser @cooked={{this.cooked}} />`);

      const text = queryAll(".chat-message-collapser p");

      assert.strictEqual(text.length, 3, "shows all written text");
      assert.dom(text[0]).hasText("written text", "first line of written text");
      assert
        .dom(text[1])
        .hasText("more written text", "third line of written text");
      assert
        .dom(text[2])
        .hasText("and even more", "fifth line of written text");
    });

    test("collapses and expands cooked youtube", async function (assert) {
      this.set("cooked", youtubeCooked);

      await render(hbs`<ChatMessageCollapser @cooked={{this.cooked}} />`);

      const youtubeDivs = queryAll(".youtube-onebox");

      assert.strictEqual(
        youtubeDivs.length,
        2,
        "two youtube previews rendered"
      );

      await click(".chat-message-collapser-opened");

      assert
        .dom(".youtube-onebox[data-video-id='ytId1']")
        .isNotVisible("first youtube preview hidden");
      assert
        .dom(".youtube-onebox[data-video-id='ytId2']")
        .isVisible("second youtube preview still visible");

      await click(".chat-message-collapser-closed");

      assert.strictEqual(
        youtubeDivs.length,
        2,
        "two youtube previews rendered"
      );

      await click(queryAll(".chat-message-collapser-opened")[1]);

      assert
        .dom(".youtube-onebox[data-video-id='ytId1']")
        .isVisible("first youtube preview still visible");
      assert
        .dom(".youtube-onebox[data-video-id='ytId2']")
        .isNotVisible("second youtube preview hidden");

      await click(".chat-message-collapser-closed");

      assert.strictEqual(
        youtubeDivs.length,
        2,
        "two youtube previews rendered"
      );
    });
  }
);

module(
  "Discourse Chat | Component | chat message collapser images",
  function (hooks) {
    setupRenderingTest(hooks);
    const imageTextCooked = "<p>A picture of Tomtom</p>";

    test("shows filename for one image", async function (assert) {
      this.set("cooked", imageTextCooked);
      this.set("uploads", [{ original_filename: "tomtom.jpeg" }]);

      await render(
        hbs`<ChatMessageCollapser @cooked={{this.cooked}} @uploads={{this.uploads}} />`
      );

      assert
        .dom(".chat-message-collapser-link-small")
        .includesText("tomtom.jpeg");
    });

    test("shows number of files for multiple images", async function (assert) {
      this.set("cooked", imageTextCooked);
      this.set("uploads", [{}, {}]);

      await render(
        hbs`<ChatMessageCollapser @cooked={{this.cooked}} @uploads={{this.uploads}} />`
      );

      assert.dom(".chat-message-collapser-link-small").includesText("2 files");
    });

    test("collapses and expands images", async function (assert) {
      this.set("cooked", imageTextCooked);
      this.set("uploads", [
        {
          original_filename: "tomtom.png",
          url: "images/d-logo-sketch-small.png",
          width: 16,
          height: 16,
        },
      ]);

      await render(
        hbs`<ChatMessageCollapser @cooked={{this.cooked}} @uploads={{this.uploads}} />`
      );

      assert.dom(".chat-uploads").isVisible();
      assert.dom(".chat-img-upload").isVisible();

      await click(".chat-message-collapser-opened");
      assert.dom(".chat-uploads").isNotVisible();
      assert.dom(".chat-img-upload").isNotVisible();

      await click(".chat-message-collapser-closed");
      assert.dom(".chat-uploads").isVisible();
      assert.dom(".chat-img-upload").isVisible();
    });
  }
);

module(
  "Discourse Chat | Component | chat message collapser animated image",
  function (hooks) {
    setupRenderingTest(hooks);

    test("shows links for animated image", async function (assert) {
      this.set("cooked", animatedImageCooked);

      await render(hbs`<ChatMessageCollapser @cooked={{this.cooked}} />`);

      const links = queryAll("a.chat-message-collapser-link-small");

      assert.dom(links[0]).includesText("avatar.png");
      assert.dom(links[0]).hasAttribute("href", "/images/avatar.png");

      assert.dom(links[1]).includesText("d-logo-sketch-small.png");
      assert
        .dom(links[1])
        .hasAttribute("href", "/images/d-logo-sketch-small.png");
    });

    test("shows all user written text", async function (assert) {
      this.set("cooked", animatedImageCooked);

      await render(hbs`<ChatMessageCollapser @cooked={{this.cooked}} />`);

      const text = queryAll(".chat-message-collapser p");

      assert.strictEqual(text.length, 5, "shows all written text");
      assert.dom(text[0]).hasText("written text");
      assert.dom(text[2]).hasText("more written text");
      assert.dom(text[4]).hasText("and even more");
    });

    test("collapses and expands animated image onebox", async function (assert) {
      this.set("cooked", animatedImageCooked);

      await render(hbs`<ChatMessageCollapser @cooked={{this.cooked}} />`);

      const animatedOneboxes = queryAll(".animated.onebox");

      assert.strictEqual(animatedOneboxes.length, 2, "two oneboxes rendered");

      await click(".chat-message-collapser-opened");

      assert
        .dom(".onebox[src='/images/avatar.png']")
        .isNotVisible("first onebox hidden");
      assert
        .dom(".onebox[src='/images/d-logo-sketch-small.png']")
        .isVisible("second onebox still visible");

      await click(".chat-message-collapser-closed");

      assert.strictEqual(animatedOneboxes.length, 2, "two oneboxes rendered");

      await click(queryAll(".chat-message-collapser-opened")[1]);

      assert
        .dom(".onebox[src='/images/avatar.png']")
        .isVisible("first onebox still visible");
      assert
        .dom(".onebox[src='/images/d-logo-sketch-small.png']")
        .isNotVisible("second onebox hidden");

      await click(".chat-message-collapser-closed");

      assert.strictEqual(animatedOneboxes.length, 2, "two oneboxes rendered");
    });
  }
);

module(
  "Discourse Chat | Component | chat message collapser external image onebox",
  function (hooks) {
    setupRenderingTest(hooks);

    test("shows links for animated image", async function (assert) {
      this.set("cooked", externalImageCooked);

      await render(hbs`<ChatMessageCollapser @cooked={{this.cooked}} />`);

      const links = queryAll("a.chat-message-collapser-link-small");

      assert.dom(links[0]).includesText("http://cat1.com");
      assert.dom(links[0]).hasAttribute("href", "http://cat1.com/");

      assert.dom(links[1]).includesText("http://cat2.com");
      assert.dom(links[1]).hasAttribute("href", "http://cat2.com/");
    });

    test("shows all user written text", async function (assert) {
      this.set("cooked", externalImageCooked);

      await render(hbs`<ChatMessageCollapser @cooked={{this.cooked}} />`);

      const text = queryAll(".chat-message-collapser p");

      assert.strictEqual(text.length, 5, "shows all written text");
      assert.dom(text[0]).hasText("written text");
      assert.dom(text[2]).hasText("more written text");
      assert.dom(text[4]).hasText("and even more");
    });

    test("collapses and expands image oneboxes", async function (assert) {
      this.set("cooked", externalImageCooked);

      await render(hbs`<ChatMessageCollapser @cooked={{this.cooked}} />`);

      const imageOneboxes = queryAll(".onebox");

      assert.strictEqual(imageOneboxes.length, 2, "two oneboxes rendered");

      await click(".chat-message-collapser-opened");

      assert
        .dom(".onebox[href='http://cat1.com']")
        .isNotVisible("first onebox hidden");
      assert
        .dom(".onebox[href='http://cat2.com']")
        .isVisible("second onebox still visible");

      await click(".chat-message-collapser-closed");

      assert.strictEqual(imageOneboxes.length, 2, "two oneboxes rendered");

      await click(queryAll(".chat-message-collapser-opened")[1]);

      assert
        .dom(".onebox[href='http://cat1.com']")
        .isVisible("first onebox still visible");
      assert
        .dom(".onebox[href='http://cat2.com']")
        .isNotVisible("second onebox hidden");

      await click(".chat-message-collapser-closed");

      assert.strictEqual(imageOneboxes.length, 2, "two oneboxes rendered");
    });
  }
);

module(
  "Discourse Chat | Component | chat message collapser images",
  function (hooks) {
    setupRenderingTest(hooks);

    skip("escapes link", async function (assert) {
      this.set(
        "cooked",
        imageCooked
          .replace("shows alt", evilString)
          .replace("/images/d-logo-sketch-small.png", evilString)
      );
      await render(hbs`<ChatMessageCollapser @cooked={{this.cooked}} />`);

      const links = [
        ...document.querySelectorAll(".chat-message-collapser-link-small"),
      ];

      assert.dom(links[0]).includesHtml(evilStringEscaped);
      assert
        .dom(links[1])
        .includesHtml("&lt;script&gt;someeviltitle&lt;/script&gt;");
    });

    test("shows alt or links (if no alt) for linked image", async function (assert) {
      this.set("cooked", imageCooked);

      await render(hbs`<ChatMessageCollapser @cooked={{this.cooked}} />`);

      const links = queryAll("a.chat-message-collapser-link-small");

      assert.dom(links[0]).includesText("shows alt");
      assert.dom(links[0]).hasAttribute("href", "/images/avatar.png");

      assert.dom(links[1]).includesText("/images/d-logo-sketch-small.png");
      assert
        .dom(links[1])
        .hasAttribute("href", "/images/d-logo-sketch-small.png");
    });

    test("shows all user written text", async function (assert) {
      this.set("cooked", imageCooked);

      await render(hbs`<ChatMessageCollapser @cooked={{this.cooked}} />`);

      const text = queryAll(".chat-message-collapser p");

      assert.strictEqual(text.length, 6, "shows all written text");
      assert.dom(text[0]).hasText("written text");
      assert.dom(text[2]).hasText("more written text");
      assert.dom(text[4]).hasText("and even more");
    });

    test("collapses and expands images", async function (assert) {
      this.set("cooked", imageCooked);

      await render(hbs`<ChatMessageCollapser @cooked={{this.cooked}} />`);

      const images = queryAll("img");

      assert.strictEqual(images.length, 3);

      await click(".chat-message-collapser-opened");

      assert
        .dom("img[src='/images/avatar.png']")
        .isNotVisible("first image hidden");
      assert
        .dom("img[src='/images/d-logo-sketch-small.png']")
        .isVisible("second image still visible");

      await click(".chat-message-collapser-closed");

      assert.strictEqual(images.length, 3);

      await click(queryAll(".chat-message-collapser-opened")[1]);

      assert
        .dom("img[src='/images/avatar.png']")
        .isVisible("first image still visible");
      assert
        .dom("img[src='/images/d-logo-sketch-small.png']")
        .isNotVisible("second image hidden");

      await click(".chat-message-collapser-closed");

      assert.strictEqual(images.length, 3);
    });

    test("does not show collapser for emoji images", async function (assert) {
      this.set("cooked", imageCooked);

      await render(hbs`<ChatMessageCollapser @cooked={{this.cooked}} />`);

      const links = queryAll("a.chat-message-collapser-link-small");
      const images = queryAll("img");
      const collapser = queryAll(".chat-message-collapser-opened");

      assert.strictEqual(links.length, 2);
      assert.strictEqual(images.length, 3, "shows images and emoji");
      assert.strictEqual(collapser.length, 2);
    });
  }
);

module(
  "Discourse Chat | Component | chat message collapser galleries",
  function (hooks) {
    setupRenderingTest(hooks);

    test("escapes title/link", async function (assert) {
      this.set(
        "cooked",
        galleryCooked
          .replace("https://imgur.com/gallery/yyVx5lJ", evilString)
          .replace("Le tomtom album", evilString)
      );
      await render(hbs`<ChatMessageCollapser @cooked={{this.cooked}} />`);

      assert
        .dom(".chat-message-collapser-link-small")
        .hasProperty("href", /%3Cscript%3Esomeeviltitle%3C\/script%3E$/);
      assert.dom(".chat-message-collapser-link-small").hasHtml("someeviltitle");
    });

    test("removes album title overlay", async function (assert) {
      this.set("cooked", galleryCooked);

      await render(hbs`<ChatMessageCollapser @cooked={{this.cooked}} />`);

      assert.dom(".album-title").doesNotExist("album title removed");
    });

    test("shows gallery link", async function (assert) {
      this.set("cooked", galleryCooked);

      await render(hbs`<ChatMessageCollapser @cooked={{this.cooked}} />`);

      assert
        .dom(".chat-message-collapser-link-small")
        .includesText("Le tomtom album");
    });

    test("shows all user written text", async function (assert) {
      this.set("cooked", galleryCooked);

      await render(hbs`<ChatMessageCollapser @cooked={{this.cooked}} />`);

      const text = queryAll(".chat-message-collapser p");

      assert.strictEqual(text.length, 2, "shows all written text");
      assert.dom(text[0]).hasText("written text");
      assert.dom(text[1]).hasText("more written text");
    });

    test("collapses and expands images", async function (assert) {
      this.set("cooked", galleryCooked);

      await render(hbs`<ChatMessageCollapser @cooked={{this.cooked}} />`);

      assert.dom("img").isVisible("image visible initially");

      await click(".chat-message-collapser-opened");
      assert.dom("img").isNotVisible("image hidden");

      await click(".chat-message-collapser-closed");
      assert.dom("img").isVisible("image visible initially");
    });
  }
);
