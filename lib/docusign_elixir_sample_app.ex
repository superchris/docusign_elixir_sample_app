defmodule DocusignElixirSampleApp do
  @moduledoc """
  Documentation for DocusignElixirSampleApp.
  """
  require Logger
  alias DocuSign.Api

  alias DocuSign.Model.EnvelopeDefinition
  alias DocuSign.Model.TemplateRole
  alias DocuSign.Model.EnvelopeSummary
  alias DocuSign.Model.EnvelopeRecipientTabs
  alias DocuSign.Model.RecipientViewRequest
  alias DocuSign.Model.Text
  alias DocuSign.Model.{EnvelopeRecipients, Signer}

  @doc """
  Fetches all envelopes younger than 30 days.
  """
  @spec get_envelopes :: {:ok, list(DocuSign.Model.Envelopes.t())} | {:error, binary}
  def get_envelopes do
    from_date = Timex.shift(Date.utc_today(), days: -30)
    Logger.debug("Fetching envelopes...")

    # There's a mismatch in 1st param type here and in func spec
    case Api.Envelopes.envelopes_get_envelopes(connection(), account_id(), from_date: from_date) do
      {:ok, %DocuSign.Model.EnvelopesInformation{envelopes: envelopes}} ->
        Logger.debug("Fetched envelopes: #{inspect(envelopes)}")
        {:ok, envelopes}

      {:error, %Tesla.Env{body: error}} ->
        Logger.error(inspect(error))
        {:error, error}
    end
  end

  @doc """
  Sending a file to Docusign.
  """
  @spec send_envelop() :: {:ok, DocuSign.Model.EnvelopeDefinition.t()} | {:error, binary}
  def send_envelop do
    Logger.debug("Preparing envelopes...")

    documents =
      Enum.map(~w(docx html pdf), fn ext ->
        %DocuSign.Model.Document{
          documentBase64: Base.encode64(File.read!("priv/samples/sample.#{ext}")),
          name: "elixir.#{ext}",
          fileExtension: ext,
          documentId: Timex.to_unix(Timex.now())
        }
      end)

    definition = %DocuSign.Model.EnvelopeDefinition{
      emailSubject: "Please sign this documents sent from Elixir SDK",
      documents: documents
    }

    Logger.debug("Sending envelopes...")

    case Api.Envelopes.envelopes_post_envelopes(connection(), account_id(),
           envelopeDefinition: definition
         ) do
      {:ok, %DocuSign.Model.EnvelopeSummary{} = envelope_summary} ->
        Logger.debug("Envelopes has been sent.")
        envelope_summary

      {:error, %Tesla.Env{body: error}} ->
        Logger.error(inspect(error))
        {:error, error}
    end
  end

  def sign_it() do
    envelope = %EnvelopeDefinition{
      templateId: "ffb607c1-1f02-4d42-8948-6259bf39fca7",
      # recipients: %EnvelopeRecipients{
      #   signers: [%Signer{
      #     email: "superchrisnelson@gmail.com",
      #     userId: "12345"
      #   }]
      # },
      status: "sent",
      templateRoles: [
        %TemplateRole{
          clientUserId: "12345",
          roleName: "Client",
          email: "superchrisnelson@gmail.com",
          name: "Chris Nelson",
          tabs: %EnvelopeRecipientTabs{
            textTabs: [
              %Text{
                tabLabel: "birth_date",
                value: "10/11/1972"
              },
              %Text{
                tabLabel: "address",
                value: "641 Evangeline Rd Cincinnati OH 45240"
              }
            ]
          }
        }
      ]
    }

    {:ok, %EnvelopeSummary{envelopeId: envelopeId}} =
      Api.Envelopes.envelopes_post_envelopes(connection(), account_id(),
        envelopeDefinition: envelope
      )

    view_req = %RecipientViewRequest{
      email: "superchrisnelson@gmail.com",
      userName: "Chris Nelson",
      authenticationMethod: "password",
      returnUrl: "https://hhaa-dev.home52.org",
      clientUserId: "12345"
    }

    {:ok, stuff} =
      Api.EnvelopeViews.views_post_envelope_recipient_view(connection(), account_id(), envelopeId,
        recipientViewRequest: view_req
      )

    IO.inspect(stuff)
  end

  defp connection, do: DocuSign.Connection.new(client: DocuSign.APIClient.client())
  defp account_id, do: Application.get_env(:docusign, :account_id)
end
