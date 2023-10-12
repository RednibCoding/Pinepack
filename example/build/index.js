/*****  pinepack___components___my_component   *****/
(function() {
let title = "My Component";

    let getTitle = () => {
        let title = "lollolo"
        return title;
    }

document.addEventListener("DOMContentLoaded", () => {
  document.querySelectorAll("#pinepack___components___my_component [data-innerHTML]").forEach((elem) => {
    const attributeValue = elem.getAttribute("data-innerHTML");
    const localValue = eval(attributeValue);
    if (typeof localValue === "function") {
      elem.innerHTML = localValue();
    } else {
      elem.innerHTML = localValue;
    }
  });
});})();

