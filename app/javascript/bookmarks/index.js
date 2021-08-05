import Rails from "@rails/ujs"

var loadMore = function() {
	var moreLink = document.getElementById("more_link");
	if (!moreLink) {
		console.log("No more pages");
		// document.getElementById("pagination").innerHTML = "";
		incrementalStop();
		return;
	}

	if (moreLink.dataset.loading) {
		return;
	}

	var viewBottom = document.documentElement.scrollTop + document.documentElement.clientHeight * 1.25;
	var list = document.getElementById("bookmarks");
	var listBottom = list.offsetTop + list.clientHeight;

	if (viewBottom >= listBottom) {
		console.log("Loading next page");

		moreLink.dataset.loading = true;
		Rails.ajax({
			url: moreLink.dataset.href,
			type: "get",
			dataType: "json",
			success: function(data) {
				console.log(`Adding page ${data["page"]}`);
				document.getElementById("bookmarks").insertAdjacentHTML("beforeend", data["bookmarks"]);
				document.getElementById("pagination").innerHTML = data["pagination"];
				console.log(`Added page ${data["page"]}`);

				loadMore();
			},
			error: function(data) {
				console.log(`Failed to load next page: ${data}`);
			}
		})
	}
};

export function incrementalStart() {
	window.addEventListener("resize", loadMore);
	window.addEventListener("scroll", loadMore);
	window.addEventListener("load", loadMore);
	console.log("Automatic page loading enabled");
};

export function incrementalStop() {
	window.removeEventListener("resize", loadMore);
	window.removeEventListener("scroll", loadMore);
	window.removeEventListener("load", loadMore);
	console.log("Automatic page loading disabled");
};
